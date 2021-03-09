# 基于 ARM Cortex-M3 处理器与 FPGA 的实时人脸检测 SOC
原创作品，转载请联系作者并注明出处：<https://github.com/WalkerLau>

源码地址：https://github.com/WalkerLau/DetectHumanFaces

本项目是第四届集成电路创新创业大赛（ARM杯）的参赛作品，包含了详细的技术文档、软件配置教程以及完整的代码。

## 项目描述
我们采用ARM Cortex-M3软核及FPGA构成了轻量级的实时人脸检测SOC，通过ov5640摄像头采集实时图像，经过检测系统的检测后，将已经框出人脸的实时图像通过HDMI输出到显示器，同时可以通过UART查看检测时间等信息，还能通过板载LED灯查看检测到的人脸数量。

我们采用的算法是 [Nenad Markus](https://github.com/nenadmarkus) 提供的 [Pixel Intensity Comparison-based Object detection](https://github.com/nenadmarkus/pico) ，该算法可以快速检测出人脸的位置与数量。

我们的人脸检测系统的特点如下：

* **速度快**：我们为SOC设计了运算加速器，最终实现了18帧/秒的检测速度。关于加速器的详细介绍请看《[TechSpecification](https://github.com/WalkerLau/DetectHumanFaces/blob/master/TechSpecification.md)》。

* **节省硬件资源**：采用低成本的Cortex-M3处理器及FPGA实现。
  
## 实现效果
经过Cortex-M3及硬件加速器的运算后，我们的人脸检测系统可以实现18帧/秒的检测能力。

<div align="center"><img src="https://raw.githubusercontent.com/WalkerLau/DetectHumanFaces/master/images/show.png" width=80%></div> 
<div align="center"><img src="https://raw.githubusercontent.com/WalkerLau/DetectHumanFaces/master/images/accComp.png" width=80%></div>


## 硬件及软件平台
* 硬件：

  * 开发板：黑金 ALINX AX7050
  
  * FPGA 芯片：Xilinx Spartan7 XC7S50
  
  * 摄像头：OmniVision(豪威) OV5640 

* 软件：
  
  * Keil MDK v5.29
  
  * vivado 2019.2
  
<div align="center"><img src="https://raw.githubusercontent.com/WalkerLau/DetectHumanFaces/master/images/resource.png" width=80%></div>
<p align="center" style="font-size:10px;color:#C0C0C0">FPGA资源消耗量</p>

## 系统的技术细节
关于本人脸检测系统的具体技术细节，如系统架构、检测算法、加速器的设计等，都可以在本 Github repo 的《[TechSpecification](https://github.com/WalkerLau/DetectHumanFaces/blob/master/TechSpecification.md)》中找到。

文件 `Docs/Keil and Vivado Configurations.pdf` 详细介绍了Keil与Vivado IP的配置。

文件夹 `hardware` 包含了所有硬件代码（Verilog代码）、约束文件和决策树参数文件 `facefinder.coe`（.coe文件用于初始化Block RAM）。

文件夹 `software` 包含了所有软件代码（C代码等），创建完Keil项目之后需将该文件夹里的所有文件添加到项目。

`files/minSOC.hex` 是Keil编译好的机械码，用于在vivado中初始化ROM。

`files/minSOC.bit` 是vivado编译好的比特流文件，仅可用于 “黑金 ALINX AX7050” 开发板的下板。

`facefinder.coe`是决策树参数文件，需要添加到BRAM中，如何添加请留意`Docs/Keil and Vivado Configurations.pdf`关于Block memory一节。

## 联系作者
Xuanzhi LIU (xuanzhi@mail.ustc.edu.cn)

Qiao HU (qhu@mail.ustc.edu.cn)

Zongwu HE (zwhe1@mail.ustc.edu.cn)
