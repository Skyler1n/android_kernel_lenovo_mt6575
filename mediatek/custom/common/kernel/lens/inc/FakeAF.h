#ifndef _FAKEAF_H
#define _FAKEAF_H

#include <linux/ioctl.h>
//#include "kd_imgsensor.h"

#define FAKEAF_MAGIC 'A'
//IOCTRL(inode * ,file * ,cmd ,arg )


//Structures
typedef struct {
//current position
unsigned long u4CurrentPosition;
//macro position
unsigned long u4MacroPosition;
//Infiniti position
unsigned long u4InfPosition;
//Motor Status
bool          bIsMotorMoving;
//Motor Open?
bool          bIsMotorOpen;
} stFakeAF_MotorInfo;

//Control commnad
//S means "set through a ptr"
//T means "tell by a arg value"
//G means "get by a ptr"             
//Q means "get by return a value"
//X means "switch G and S atomically"
//H means "switch T and Q atomically"
#define FAKEAFIOC_G_MOTORINFO _IOR(FAKEAF_MAGIC,0,stFakeAF_MotorInfo)

#define FAKEAFIOC_T_MOVETO _IOW(FAKEAF_MAGIC,1,unsigned long)

#define FAKEAFIOC_T_SETINFPOS _IOW(FAKEAF_MAGIC,2,unsigned long)

#define FAKEAFIOC_T_SETMACROPOS _IOW(FAKEAF_MAGIC,3,unsigned long)

#else
#endif
