#ifndef META_CUST_BT_H
#define META_CUST_BT_H

#if defined(MTK_MT6620)
/* SERIAL PORT */
#define CUST_BT_SERIAL_PORT "/dev/stpbt"
/* BAUDRATE */
#define CUST_BT_BAUD_RATE   4000000 /*use 4M but is not controlled by bt directly */
#else
/* SERIAL PORT */
#define CUST_BT_SERIAL_PORT "/dev/ttyMT2"
/* BAUDRATE */
#define CUST_BT_BAUD_RATE   3250000
//#define CUST_BT_BAUD_RATE   921600
#endif


/* MTK BT SOLUTION */
//#define MTK_MT6611_E4
//#define MTK_MT6611_E4
//#define MTK_MT6616_E3
#endif /* FTM_CUST_BT_H */
