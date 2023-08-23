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

#define MAX(a, b) ((a)>(b)?(a):(b))
#define MIN(a, b) ((a)<(b)?(a):(b))

#include <stdint.h>
#include <stdio.h>
#include "./CM3DS_MPS2_driver.h"

/*

*/

/*************************************
 * 级联分类器:
 * 历遍ntrees棵树，每棵树进行6层二分类，最终获得一个confidence，
 * 每棵树的confidence不断进行累加，与阈值对比，从而判断该位置的检测区域是否为有效目标，
 * 若为有效目标，则通过指针返回该区域的confidence
 * 参数：
 * *** o 是 confidence，通过指针返回
 * *** r/c/s 分别是当前检测窗的位置与大小（row/column/scale）
 * *** vppixels 原图的灰度图
 *************************************/
int run_cascade(void* cascade, float* o, int r, int c, int s, void* vppixels, int nrows, int ncols, int ldim)
{
	int* rcs = (int*) 0x28400000UL;
	rcs[0] = (int)r; rcs[1] = (int)c; rcs[2] = (int)s; 
	accStart();
	WaitForReturn();
	uint32_t* return_p = 0x2840000cUL;
	float* o_p = 0x28400010UL;
	
	*o = *o_p;
	return *return_p;

	
//	////////////////////////////////////////////////////////////////////////////////////////////////////////
//	int i, j, idx;
//
//	uint8_t* pixels;
//
//	int tdepth, ntrees, offset;
//
//	int8_t* ptree;
//	int8_t* tcodes;
//	float* lut;
//	float thr;
//
//	//
//	pixels = (uint8_t*)vppixels;
//
//	// cascade参数文件的头信息以32位int形式储存
//	tdepth = ((int*)cascade)[2];	// 树的深度，每棵树的深度都是6
//	ntrees = ((int*)cascade)[3];	// cascade中树的总数，参数中一共有468棵树的数据
//
//	// 乘以256是因为后面的tcodes用的是int8_t类型，数值范围较大，后面还会除以256来恢复
//	r = r*256;
//	c = c*256;
//
//	// 以(c,r)点为中心，探测边长为s的正方形检测区是否超出原图边界
//	if (((r + (s << 7)) >> 8) >= nrows || ((r - (s << 7)) >> 8) < 0 || ((c + (s << 7)) >> 8) >= ncols || ((c - (s << 7)) >> 8) < 0)
//		return -1;
//
//	// ptree的offset值，每棵树之间的地址间隔为offset 
//	offset = ((1<<tdepth)-1)*sizeof(int32_t) + (1<<tdepth)*sizeof(float) + 1*sizeof(float);
//	/******************************************************
//	 * ptree是指向树的指针，单位是8位int类型；
//	 * 每棵树的数据由tcodes、lut、thr三个部件组成：
//	 * ** tcodes（占((1<<tdepth)-1)*sizeof(int32_t)）：决定了要对比强度的像素的移动轨迹
//	 * ** lut（占(1<<tdepth)*sizeof(float)）：储存了这棵树所有可能决策结果对应的confidence
//	 * ** thr（占sizeof(float)）：confidence阈值
//	 * 初始化ptree：加了2个float和2个int类型的offset后才指向树，证明cascade参数文件头信息一开始是2个int和两个float数据
//	 ******************************************************/
//	ptree = (int8_t*)cascade + 2*sizeof(float) + 2*sizeof(int);
//
//	*o = 0.0f;
//
//	for(i=0; i<ntrees; ++i)
//	{
//		//
//		tcodes = ptree - 4;		// -4是因为后面的idx初始化为1，使得tcodes[4*idx]是从tcodes[0]开始的
//		lut = (float*)(ptree + ((1<<tdepth)-1)*sizeof(int32_t));	// 1<<tdepth 巧妙地扁平化了层级结构的二元决策树，有点像神经网络的receptive field
//		thr = *(float*)(ptree + ((1<<tdepth)-1)*sizeof(int32_t) + (1<<tdepth)*sizeof(float));
//
//		//
//		idx = 1;
//		
//		// 一棵树沿深度方向的二元决策，决策判据是这棵树各层所指定图像位置的强度
//		// 经过tdepth（6层）决策后，得到最终所落在的位置是 idx-(1<<tdepth)
//		// 减去(1<<tdepth)是因为(1<<tdepth)是一个偏移值，使得对于最终的lut[n]，有n在整数区间[0,63]的范围内
//		// tcodes[4*idx+0]中的4是因为tcodes地址的数据（int_8类型）每4个为一组
//		for (j = 0; j < tdepth; ++j)
//			idx = 2 * idx + (pixels[((r + tcodes[4 * idx + 0] * s) >> 8) * ldim + ((c + tcodes[4 * idx + 1] * s) >> 8)]
//				<= pixels[((r + tcodes[4 * idx + 2] * s) >> 8) * ldim + ((c + tcodes[4 * idx + 3] * s) >> 8)]);
//
//		// 论文说对每棵树的output（决策confidence）进行累加，并threshold
//		*o = *o + lut[idx-(1<<tdepth)];	
//
//		// 
//		if(*o<=thr)
//			return -1;	// confidence低于阈值的目标将马上被排除，run_cascade返回-1
//		else
//			ptree = ptree + offset;	// 高于阈值的目标可以继续
//	}
//
//	//
//	*o = *o - thr;
//
//	return +1;
}

int run_rotated_cascade(void* cascade, float* o, int r, int c, int s, float a, void* vppixels, int nrows, int ncols, int ldim)
{
	//
	int i, j, idx;

	uint8_t* pixels;

	int tdepth, ntrees, offset;

	int8_t* ptree;
	int8_t* tcodes;
	float* lut;
	float thr;

	static int qcostable[32+1] = {256, 251, 236, 212, 181, 142, 97, 49, 0, -49, -97, -142, -181, -212, -236, -251, -256, -251, -236, -212, -181, -142, -97, -49, 0, 49, 97, 142, 181, 212, 236, 251, 256};
	static int qsintable[32+1] = {0, 49, 97, 142, 181, 212, 236, 251, 256, 251, 236, 212, 181, 142, 97, 49, 0, -49, -97, -142, -181, -212, -236, -251, -256, -251, -236, -212, -181, -142, -97, -49, 0};

	//
	pixels = (uint8_t*)vppixels;

	//
	tdepth = ((int*)cascade)[2];
	ntrees = ((int*)cascade)[3];

	//
	r = r*65536;
	c = c*65536;

	if( (r+46341*s)/65536>=nrows || (r-46341*s)/65536<0 || (c+46341*s)/65536>=ncols || (c-46341*s)/65536<0 )
		return -1;

	//
	offset = ((1<<tdepth)-1)*sizeof(int32_t) + (1<<tdepth)*sizeof(float) + 1*sizeof(float);
	ptree = (int8_t*)cascade + 2*sizeof(float) + 2*sizeof(int);

	*o = 0.0f;

	int qsin = s*qsintable[(int)(32*a)]; //s*(int)(256.0f*sinf(2*M_PI*a));
	int qcos = s*qcostable[(int)(32*a)]; //s*(int)(256.0f*cosf(2*M_PI*a));

	for(i=0; i<ntrees; ++i)
	{
		//
		tcodes = ptree - 4;
		lut = (float*)(ptree + ((1<<tdepth)-1)*sizeof(int32_t));
		thr = *(float*)(ptree + ((1<<tdepth)-1)*sizeof(int32_t) + (1<<tdepth)*sizeof(float));

		//
		idx = 1;

		for(j=0; j<tdepth; ++j)
		{
			int r1, c1, r2, c2;

			//
			r1 = (r + qcos*tcodes[4*idx+0] - qsin*tcodes[4*idx+1])/65536;
			c1 = (c + qsin*tcodes[4*idx+0] + qcos*tcodes[4*idx+1])/65536;

			r2 = (r + qcos*tcodes[4*idx+2] - qsin*tcodes[4*idx+3])/65536;
			c2 = (c + qsin*tcodes[4*idx+2] + qcos*tcodes[4*idx+3])/65536;

			//
			idx = 2*idx + (pixels[r1*ldim+c1]<=pixels[r2*ldim+c2]);
		}

		*o = *o + lut[idx-(1<<tdepth)];

		//
		if(*o<=thr)
			return -1;
		else
			ptree = ptree + offset;
	}

	//
	*o = *o - thr;

	return +1;
}

/***********************************
 * rcsq储存并返回所检测到的有效目标的位置、尺寸、confidence
 * maxndetections，最大可检测目标数
 * cascade是级联分类器参数文件
 * pixels是摄像头拍到的整张图片（单通道灰度图）
 * 函数返回检测到的有效目标数目
 ***********************************/
int find_objects
(
	float rcsq[], int maxndetections,
	void* cascade, float angle, // * `angle` is a number between 0 and 1 that determines the counterclockwise in-plane rotation of the cascade: 0.0f corresponds to 0 radians and 1.0f corresponds to 2*pi radians
	void* pixels, int nrows, int ncols, int ldim,
	float scalefactor, float stridefactor, float minsize, float maxsize
)
{
	float s;	// 目标检测区（正方形）的边长	
	int ndetections;	// number of detections，检测到的目标数量

	//
	ndetections = 0;
	s = minsize;
	int totalTime = 0; //chg
	int checkTime; //chg
	int iter = 0; //chg

	int* 		rcs1 = (int*) 0x28400000UL;
	int*		rcs2 = (int*) 0x28400010UL;
	float*		q1 = 0x28500000UL;
	float*		q2 = 0x28500010UL;
	uint32_t* 	t1 = 0x28500004UL;
	uint32_t* 	t2 = 0x28500014UL;

	while(s<=maxsize)
	{
		float r;
		float c1, c2;
		float dr, dc;

		dr = dc = MAX(stridefactor*s, 1.0f);

		// 将级联分类器在原图上进行横轴、纵轴移窗
		for(r=s/2+1; r<=nrows-s/2-1; r+=dr){
			for(c1=s/2+1; c1<=ncols-s/2-1; c1+=2*dc){

				*t1 = 0; *t2 = 0;

				c2 = c1 + dc;

				rcs1[0] = r; rcs1[1] = c1; rcs1[2] = s;
				rcs2[0] = r; rcs2[1] = c2; rcs2[2] = s;
				accStart();

				WaitForReturn();
      
				// if(0.0f==angle){
				// 	//rstTime();	//chg
				// 	t = run_cascade(cascade, &q, r, c, s, pixels, nrows, ncols, ldim);
				// 	//checkTime = getTime(); //chg
				// 	//totalTime += checkTime; //chg
				// 	//iter++; //chg
				// }
				// else
				// 	t = run_rotated_cascade(cascade, &q, r, c, s, angle, pixels, nrows, ncols, ldim);

				if(1==*t1)	// t=1意味着输入到cascade分类器的是有效目标
				{
					if(ndetections < maxndetections)
					{
						rcsq[4*ndetections+0] = r;		// 圆心的y坐标（行号）
						rcsq[4*ndetections+1] = c1;		// 圆心的x坐标（列号）
						rcsq[4*ndetections+2] = s;		// 目标区域的scale，即圆的直径
						rcsq[4*ndetections+3] = *q1;	// confidence
						//
						++ndetections;
					}
				}
				if(c2 <= ncols-s/2-1){
					if(1==*t2)	// t=1意味着输入到cascade分类器的是有效目标
					{
						if(ndetections < maxndetections)
						{
							rcsq[4*ndetections+0] = r;		// 圆心的y坐标（行号）
							rcsq[4*ndetections+1] = c2;		// 圆心的x坐标（列号）
							rcsq[4*ndetections+2] = s;		// 目标区域的scale，即圆的直径
							rcsq[4*ndetections+3] = *q2;	// confidence
							//
							++ndetections;
						}
					}
				}

			}
		}

		// 一轮横、纵移窗后，改变检测区大小，继续移窗
		s = scalefactor*s;
	}

	//printf("time for running run_cascade is: "); PrintFloat(totalTime/iter); printf("\n"); //chg
	//printf("iter is: "); PrintBigInt(iter); printf("\n");

	//
	return ndetections;
}

/*
	
*/

float get_overlap(float r1, float c1, float s1, float r2, float c2, float s2)
{
	float overr, overc;

	//
	overr = MAX(0, MIN(r1+s1/2, r2+s2/2) - MAX(r1-s1/2, r2-s2/2));
	overc = MAX(0, MIN(c1+s1/2, c2+s2/2) - MAX(c1-s1/2, c2-s2/2));

	//
	return overr*overc/(s1*s1+s2*s2-overr*overc);
}

void ccdfs(int a[], int i, float rcsq[], int n)
{
	int j;

	//
	for(j=0; j<n; ++j)
		if(a[j]==0 && get_overlap(rcsq[4*i+0], rcsq[4*i+1], rcsq[4*i+2], rcsq[4*j+0], rcsq[4*j+1], rcsq[4*j+2])>0.3f)
		{
			//
			a[j] = a[i];

			//
			ccdfs(a, j, rcsq, n);
		}
}

int find_connected_components(int a[], float rcsq[], int n)
{
	int i, cc;

	//
	if(!n)
		return 0;

	//
	for(i=0; i<n; ++i)
		a[i] = 0;

	//
	cc = 1;

	for(i=0; i<n; ++i)
		if(a[i] == 0)
		{
			//
			a[i] = cc;

			//
			ccdfs(a, i, rcsq, n);

			//
			++cc;
		}

	//
	return cc - 1; // number of connected components
}

// cluster_detections函数用于处理重叠的目标，把它们合并为一个。
int cluster_detections(float rcsq[], int n)
{
	int idx, ncc, cc;
	int a[4096];

	//
	ncc = find_connected_components(a, rcsq, n);

	if(!ncc)
		return 0;

	//
	idx = 0;

	for(cc=1; cc<=ncc; ++cc)
	{
		int i, k;

		float sumqs=0.0f, sumrs=0.0f, sumcs=0.0f, sumss=0.0f;

		//
		k = 0;

		for(i=0; i<n; ++i)
			if(a[i] == cc)
			{
				sumrs += rcsq[4*i+0];
				sumcs += rcsq[4*i+1];
				sumss += rcsq[4*i+2];
				sumqs += rcsq[4*i+3];

				++k;
			}

		//
		rcsq[4*idx+0] = sumrs/k;
		rcsq[4*idx+1] = sumcs/k;
		rcsq[4*idx+2] = sumss/k;;
		rcsq[4*idx+3] = sumqs; // accumulated confidence measure

		//
		++idx;
	}

	//
	return idx;
}

/*

*/

int update_memory
(
	int* slot,
	float memory[], int counts[], int nmemslots, int maxslotsize,
	float rcsq[], int ndets, int maxndets
)
{
	int i, j;

	//
	counts[*slot] = ndets;

	for(i=0; i<counts[*slot]; ++i)
	{
		memory[*slot*4*maxslotsize + 4*i + 0] = rcsq[4*i + 0];
		memory[*slot*4*maxslotsize + 4*i + 1] = rcsq[4*i + 1];
		memory[*slot*4*maxslotsize + 4*i + 2] = rcsq[4*i + 2];
		memory[*slot*4*maxslotsize + 4*i + 3] = rcsq[4*i + 3];
	}

	*slot = (*slot + 1)%nmemslots;

	//
	ndets = 0;

	for(i=0; i<nmemslots; ++i)
		for(j=0; j<counts[i]; ++j)
		{
			if(ndets >= maxndets)
				return ndets;

			rcsq[4*ndets + 0] = memory[i*4*maxslotsize + 4*j + 0];
			rcsq[4*ndets + 1] = memory[i*4*maxslotsize + 4*j + 1];
			rcsq[4*ndets + 2] = memory[i*4*maxslotsize + 4*j + 2];
			rcsq[4*ndets + 3] = memory[i*4*maxslotsize + 4*j + 3];

			++ndets;
		}

	return ndets;
}