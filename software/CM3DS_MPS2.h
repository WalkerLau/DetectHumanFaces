#ifndef CM3DS_MPS2_H
#define CM3DS_MPS2_H

#ifdef __cplusplus
 extern "C" {
#endif

/** @addtogroup CM3DS_MPS2_Definitions CM3DS_MPS2 Definitions
  This file defines all structures and symbols for CM3DS_MPS2:
    - registers and bitfields
    - peripheral base address
    - peripheral ID
    - Peripheral definitions
  @{
*/

#include <stdint.h>


/******************************************************************************/
/*                Processor and Core Peripherals                              */
/******************************************************************************/
/** @addtogroup CM3DS_MPS2_CMSIS Device CMSIS Definitions
  Configuration of the Cortex-M3 Processor and Core Peripherals
  @{
*/

/*
 * ==========================================================================
 * ---------- Interrupt Number Definition -----------------------------------
 * ==========================================================================
 */

typedef enum IRQn
{
/******  Cortex-M3 Processor Exceptions Numbers ***************************************************/
  NonMaskableInt_IRQn           = -14,    /*!<  2 Cortex-M3 Non Maskable Interrupt                        */
  HardFault_IRQn                = -13,    /*!<  3 Cortex-M3 Hard Fault Interrupt                          */
  MemoryManagement_IRQn         = -12,    /*!<  4 Cortex-M3 Memory Management Interrupt            */
  BusFault_IRQn                 = -11,    /*!<  5 Cortex-M3 Bus Fault Interrupt                    */
  UsageFault_IRQn               = -10,    /*!<  6 Cortex-M3 Usage Fault Interrupt                  */
  SVCall_IRQn                   = -5,     /*!< 11 Cortex-M3 SV Call Interrupt                      */
  DebugMonitor_IRQn             = -4,     /*!< 12 Cortex-M3 Debug Monitor Interrupt                */
  PendSV_IRQn                   = -2,     /*!< 14 Cortex-M3 Pend SV Interrupt                      */
  SysTick_IRQn                  = -1,     /*!< 15 Cortex-M3 System Tick Interrupt                  */

/******  CM3DS_MPS2 Specific Interrupt Numbers *******************************************************/
  UARTRX_IRQn                   = 0,       /* UART 0 RX and TX Combined Interrupt     */
  UARTTX_IRQn                   = 1,       /* Undefined                               */
  UARTOVR_IRQn                  = 2,       /* UART 1 RX and TX Combined Interrupt     */
  ACC_IRQn                      = 3,       /* Hardware Accelerator Return Interrupt   */
  CAM_IRQn                      = 4,       /* Camera Interrupt   */
} IRQn_Type;


/*
 * ==========================================================================
 * ----------- Processor and Core Peripheral Section ------------------------
 * ==========================================================================
 */

/* Configuration of the Cortex-M3 Processor and Core Peripherals */
#define __CM3_REV                 0x0201    /*!< Core Revision r2p1                             */
#define __NVIC_PRIO_BITS          3         /*!< Number of Bits used for Priority Levels        */
#define __Vendor_SysTickConfig    0         /*!< Set to 1 if different SysTick Config is used   */
#define __MPU_PRESENT             1         /*!< MPU present or not                             */

/*@}*/ /* end of group CM3DS_MPS2_CMSIS */


#include "core_cm3.h"                     /* Cortex-M3 processor and core peripherals           */
#include "system_CM3DS.h"             /* CM3DS System include file                      */


/******************************************************************************/
/*                Device Specific Peripheral registers structures             */
/******************************************************************************/
/** @addtogroup CM3DS_MPS2_Peripherals CM3DS_MPS2 Peripherals
  CM3DS_MPS2 Device Specific Peripheral registers structures
  @{
*/

#if defined ( __CC_ARM   )
  #pragma push
#pragma anon_unions
#elif defined(__ICCARM__)
  #pragma language=extended
#elif defined(__GNUC__)
  /* anonymous unions are enabled by default */
#elif defined(__TMS470__)
/* anonymous unions are enabled by default */
#elif defined(__TASKING__)
  #pragma warning 586
#else
  #warning Not supported compiler type
#endif


/*------------- Universal Asynchronous Receiver Transmitter (UART) -----------*/
typedef struct
{
  __IO   uint32_t  DATA;          /*!< Offset: 0x000 Data Register    (R/W) */
  __IO   uint32_t  STATE;         /*!< Offset: 0x004 Status Register  (R/W) */
  __IO   uint32_t  CTRL;          /*!< Offset: 0x008 Control Register (R/W) */
  union {
    __I    uint32_t  INTSTATUS;   /*!< Offset: 0x00C Interrupt Status Register (R/ ) */
    __O    uint32_t  INTCLEAR;    /*!< Offset: 0x00C Interrupt Clear Register ( /W) */
    };
  __IO   uint32_t  BAUDDIV;       /*!< Offset: 0x010 Baudrate Divider Register (R/W) */

}  UART_TypeDef;

/*  UART DATA Register Definitions */

#define  UART_DATA_Pos               0                                            /*!<  UART_DATA_Pos: DATA Position */
#define  UART_DATA_Msk              (0xFFul <<  UART_DATA_Pos)               /*!<  UART DATA: DATA Mask */

#define  UART_STATE_RXOR_Pos         3                                            /*!<  UART STATE: RXOR Position */
#define  UART_STATE_RXOR_Msk         (0x1ul <<  UART_STATE_RXOR_Pos)         /*!<  UART STATE: RXOR Mask */

#define  UART_STATE_TXOR_Pos         2                                            /*!<  UART STATE: TXOR Position */
#define  UART_STATE_TXOR_Msk         (0x1ul <<  UART_STATE_TXOR_Pos)         /*!<  UART STATE: TXOR Mask */

#define  UART_STATE_RXBF_Pos         1                                            /*!<  UART STATE: RXBF Position */
#define  UART_STATE_RXBF_Msk         (0x1ul <<  UART_STATE_RXBF_Pos)         /*!<  UART STATE: RXBF Mask */

#define  UART_STATE_TXBF_Pos         0                                            /*!<  UART STATE: TXBF Position */
#define  UART_STATE_TXBF_Msk         (0x1ul <<  UART_STATE_TXBF_Pos )        /*!<  UART STATE: TXBF Mask */

#define  UART_CTRL_HSTM_Pos          6                                            /*!<  UART CTRL: HSTM Position */
#define  UART_CTRL_HSTM_Msk          (0x01ul <<  UART_CTRL_HSTM_Pos)         /*!<  UART CTRL: HSTM Mask */

#define  UART_CTRL_RXORIRQEN_Pos     5                                            /*!<  UART CTRL: RXORIRQEN Position */
#define  UART_CTRL_RXORIRQEN_Msk     (0x01ul <<  UART_CTRL_RXORIRQEN_Pos)    /*!<  UART CTRL: RXORIRQEN Mask */

#define  UART_CTRL_TXORIRQEN_Pos     4                                            /*!<  UART CTRL: TXORIRQEN Position */
#define  UART_CTRL_TXORIRQEN_Msk     (0x01ul <<  UART_CTRL_TXORIRQEN_Pos)    /*!<  UART CTRL: TXORIRQEN Mask */

#define  UART_CTRL_RXIRQEN_Pos       3                                            /*!<  UART CTRL: RXIRQEN Position */
#define  UART_CTRL_RXIRQEN_Msk       (0x01ul <<  UART_CTRL_RXIRQEN_Pos)      /*!<  UART CTRL: RXIRQEN Mask */

#define  UART_CTRL_TXIRQEN_Pos       2                                            /*!<  UART CTRL: TXIRQEN Position */
#define  UART_CTRL_TXIRQEN_Msk       (0x01ul <<  UART_CTRL_TXIRQEN_Pos)      /*!<  UART CTRL: TXIRQEN Mask */

#define  UART_CTRL_RXEN_Pos          1                                            /*!<  UART CTRL: RXEN Position */
#define  UART_CTRL_RXEN_Msk          (0x01ul <<  UART_CTRL_RXEN_Pos)         /*!<  UART CTRL: RXEN Mask */

#define  UART_CTRL_TXEN_Pos          0                                            /*!<  UART CTRL: TXEN Position */
#define  UART_CTRL_TXEN_Msk          (0x01ul <<  UART_CTRL_TXEN_Pos)         /*!<  UART CTRL: TXEN Mask */

#define  UART_INTSTATUS_RXORIRQ_Pos  3                                            /*!<  UART CTRL: RXORIRQ Position */
#define  UART_CTRL_RXORIRQ_Msk       (0x01ul <<  UART_INTSTATUS_RXORIRQ_Pos) /*!<  UART CTRL: RXORIRQ Mask */

#define  UART_CTRL_TXORIRQ_Pos       2                                            /*!<  UART CTRL: TXORIRQ Position */
#define  UART_CTRL_TXORIRQ_Msk       (0x01ul <<  UART_CTRL_TXORIRQ_Pos)      /*!<  UART CTRL: TXORIRQ Mask */

#define  UART_CTRL_RXIRQ_Pos         1                                            /*!<  UART CTRL: RXIRQ Position */
#define  UART_CTRL_RXIRQ_Msk         (0x01ul <<  UART_CTRL_RXIRQ_Pos)        /*!<  UART CTRL: RXIRQ Mask */

#define  UART_CTRL_TXIRQ_Pos         0                                            /*!<  UART CTRL: TXIRQ Position */
#define  UART_CTRL_TXIRQ_Msk         (0x01ul <<  UART_CTRL_TXIRQ_Pos)        /*!<  UART CTRL: TXIRQ Mask */

#define  UART_BAUDDIV_Pos            0                                            /*!<  UART BAUDDIV: BAUDDIV Position */
#define  UART_BAUDDIV_Msk            (0xFFFFFul <<  UART_BAUDDIV_Pos)        /*!<  UART BAUDDIV: BAUDDIV Mask */


/*------------------- FPGA control ----------------------------------------------*/
#if defined ( __CC_ARM   )
#pragma anon_unions
#endif

typedef struct 
{
  volatile      uint32_t  BTN0;
} APB_BTN_TypeDef;

typedef struct
{
  volatile      uint32_t  LEDS;
} APB_LED_TypeDef;

typedef struct
{
  volatile      uint32_t  TIME;
} APB_TIMER_TypeDef;

typedef struct
{
  volatile      uint32_t  IGNIT;
} APB_IGNITER_TypeDef;

/*------------------ SysTick ------------------------------------------------------*/
typedef struct
{
  volatile      uint32_t CTRL;
  volatile      uint32_t LOAD;
  volatile      uint32_t VALUE;
  volatile      uint32_t CALIB;
}SysTickType;



/* --------------------  End of section using anonymous unions  ------------------- */

#if defined ( __CC_ARM   )
  #pragma pop
#elif defined(__ICCARM__)
  /* leave anonymous unions enabled */
#elif defined(__GNUC__)
  /* anonymous unions are enabled by default */
#elif defined(__TMS470__)
  /* anonymous unions are enabled by default */
#elif defined(__TASKING__)
  #pragma warning restore
#else
  #warning Not supported compiler type
#endif


/******************************************************************************/
/*                         Peripheral memory map                              */
/******************************************************************************/
/* Peripheral and SRAM base address */
#define CM3DS_MPS2_FLASH_BASE        (0x00000000UL)  /*!< (FLASH     ) Base Address */
#define CM3DS_MPS2_SRAM_BASE         (0x20000000UL)  /*!< (SRAM      ) Base Address */
#define CM3DS_MPS2_PERIPH_BASE       (0x40000000UL)  /*!< (Peripheral) Base Address */

#define CM3DS_MPS2_RAM_BASE          (0x20000000UL)
#define CM3DS_MPS2_APB_BASE          (0x40000000UL)

/* SysTick                                                                   */
#define SysTick_BASE                 (0xe000e010UL)


/* APB peripherals                                                           */
#define APB_LED_BASE                  (CM3DS_MPS2_APB_BASE + 0x0000UL)
#define APB_BTN_BASE                  (CM3DS_MPS2_APB_BASE + 0x1000UL)
#define APB_UART_BASE                 (CM3DS_MPS2_APB_BASE + 0x2000UL)
#define APB_TIME_BASE                 (CM3DS_MPS2_APB_BASE + 0x3000UL)
#define APB_IGNITER_BASE              (CM3DS_MPS2_APB_BASE + 0x4000UL)

/******************************************************************************/
/*                         Peripheral declaration                             */
/******************************************************************************/
#define SysTick                       ((SysTickType       *) SysTick_BASE         )

#define APB_LED                       ((APB_LED_TypeDef   *) APB_LED_BASE         )
#define APB_BTN                       ((APB_BTN_TypeDef   *) APB_BTN_BASE         )
#define UART                          ((UART_TypeDef      *) APB_UART_BASE        )
#define TIMER                         ((APB_TIMER_TypeDef *) APB_TIME_BASE        )
#define IGNITER                       ((APB_IGNITER_TypeDef *) APB_IGNITER_BASE   )


#ifdef __cplusplus
}
#endif

#endif  /* CM3DS_MPS2_H */

