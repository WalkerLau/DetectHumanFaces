/* *****************************************************************
 *  This code is released under the MIT License.
 *  Copyright (c) 2020 Xuanzhi LIU, Qiao HU, Zongwu HE
 *  
 *  For latest version of this code or to issue a problem, 
 *  please visit: <https://github.com/WalkerLau/DetectHumanFaces>
 *  
 *  Note: the above information must be kept whenever or wherever the codes are used.
 *  
 * *****************************************************************/

#include <stdio.h>
#include <stdint.h>

//
#include "./CM3DS_MPS2.h"
#include "./CM3DS_MPS2_driver.h"
#include "./picornt.h"
#include "./RGBprocess.h"


void PrintBigInt(int bigInt) {
	int thousand, hundred, ten, one;
	int tem1, tem2, tem3, tem4;
	thousand = (bigInt / 1000) % 10;					
	tem1 = thousand * 1000;
	hundred = ((bigInt - tem1) / 100) % 10;		
	tem2 = hundred * 100;
	ten = ((bigInt - tem1 - tem2) / 10) % 10;	
	tem3 = ten * 10;
	one = bigInt - tem1 - tem2 - tem3;
	if (bigInt > 9999 || bigInt < 0) {
		printf("Error!!! PrintBigInt out of range, should be in [0, 9999]\n");
	}
	else if ((thousand != 0)) {
		printf("%d%d%d%d", thousand, hundred, ten, one);
	}
	else if ((thousand == 0) && (hundred != 0)) {
		printf("%d%d%d", hundred, ten, one);
	}
	else if ((thousand == 0) && (hundred == 0) && (ten != 0)) {
		printf("%d%d", ten, one);
	}
	else if ((thousand == 0) && (hundred == 0) && (ten == 0) && (one != 0)) {
		printf("%d", one);
	}
	else {
		printf("0");
	}	
}

void PrintFloat(float value)
{
	int tmp, tmp1, tmp2;
	tmp = (int)value;
	tmp1 = (int)((value - tmp) * 10) % 10;
	tmp2 = (int)((value - tmp) * 100) % 10;
	PrintBigInt(tmp);
	printf(".%d%d", tmp1, tmp2);
}

void process_image(volatile uint16_t* frame, int draw, int minsize, float angle, float scalefactor, float stridefactor, int noclustering, void* cascade)
{
	int i, j;
	float t;

	uint16_t* pixels = frame;
	int nrows, ncols, ldim;

	#define MAXNDETECTIONS 1024
	int ndetections;
	float rcsq[4*MAXNDETECTIONS];

	nrows 	= ROWS;
	ncols 	= COLS;
	ldim 		= COLS; // 图像的一行数据的字节数

	//chg 计时开始
	//int durTime;
	//chg del: rstTime(); 

	//
	//int findObjectsTime; //chg
	//rstTime(); //chg
	ndetections = find_objects(rcsq, MAXNDETECTIONS, cascade, angle, pixels, nrows, ncols, ldim, scalefactor, stridefactor, minsize, MIN(nrows, ncols));
	//findObjectsTime = getTime(); //chg
	//printf("find objects time = "); PrintBigInt(findObjectsTime); printf(" ms\n"); //chg

	// cluster_detections函数用于处理重叠的目标，把它们合并为一个。
	ndetections = cluster_detections(rcsq, ndetections);

	//chg del: durTime = getTime();

  //画框框
  int x, y, side;
  int p1, p2, p3, p4;
  if (ndetections) {
   for (int i = 0; i < ndetections; i++) {
    x = (int)rcsq[4 * i + 1];
    y = (int)rcsq[4 * i + 0];
    side = (int)(rcsq[4 * i + 2] / 2);
    p1 = (x - side) + (y - 1 - side) * COLS;
    p2 = (x + side) + (y - 1 - side) * COLS;
    p3 = (x - side) + (y - 1 + side) * COLS;
    for (int j = 0; j < 2 * side; j++) {
     frame[p1 + j] = 0xF800;
     frame[p2 + j * COLS] = 0xF800;
     frame[p1 + j * COLS] = 0xF800;
     frame[p3 + j] = 0xF800;
    }
   }
  }
  AddrSwitch();

	send2LED(ndetections);
	printf("/////////////////////////////////////////////\n");
	printf("number of faces = %d\n", ndetections); 
	//chg del: printf("detection time of this frame = "); PrintBigInt(durTime); printf(" ms\n");
	
	if (ndetections) {
		for (int i = 0; i < ndetections; i++) {
			printf("--------------------------\n");
			printf("face %d info:\n", i + 1);
			printf("  location = ("); PrintFloat(rcsq[4 * i + 1]); printf(", "); PrintFloat(rcsq[4 * i + 0]); 
			printf(")\n  scale = "); PrintFloat(rcsq[4 * i + 2]); 
			printf("\n");
		}
	}

}

/***************************
 * param1 = executefile, param2 = cascadefile, param3 = picturefile
 ***************************/
int main(void){

	printf("******************\n");
  printf("cortex-m3 startup!\n");
  printf("******************\n");

  send2LED(0x01);
  delay(50000000);
  send2LED(0x03);
  delay(50000000);
  send2LED(0x07);
  delay(50000000);
  send2LED(0x0f);
  delay(50000000);
  send2LED(0x00);

	// read cascade file from DDR
	volatile void* 			cascade = (void*) 0x28000000UL;
	volatile uint8_t* 		img;

	int minsize = 128;
	int maxsize = 400;
	float angle = 0.0f;
	float scalefactor = 1.2f;
	float stridefactor = 0.18f;
	int noclustering = 0;

	//
	int processImageTime; //chg
  int pixelAddrIndex;
	while(1){
		CamStart();
		WaitForCam();
		rstTime(); //chg
    pixelAddrIndex = getIndex();
    if(1 == pixelAddrIndex){
      img = 0x2bc00000UL;
    }
    else if(0 == pixelAddrIndex){
      img = 0x2be00000UL;
    }
		process_image((uint16_t*)img, 1, minsize, angle, scalefactor, stridefactor, noclustering, cascade);
		processImageTime = getTime(); //chg
		printf("process Image Time = "); PrintBigInt(processImageTime); printf(" ms\n"); //chg
    
	}

	return 0;
}

