/*******************************************************************************
 *
 * Filename:
 * ---------
 *   cfg_bt_file.h
 *
 * Project:
 * --------
 *   DUMA
 *
 * Description:
 * ------------
 *    header file of main function
 *
 * Author:
 * -------
 *   Ning.F (MTK08139) 09/11/2008
 *
 *------------------------------------------------------------------------------
 * $Revision:$
 * $Modtime:$
 * $Log:$
 *
 * Apr 15 2009 mtk80306
 * [DUMA00204156] Power on_it display start in mobile screen
 * change default value
 *
 * Mar 21 2009 mtk80306
 * [DUMA00112158] fix the code convention.
 * change bt defualt value.
 *
 * Mar 9 2009 mtk80306
 * [DUMA00111088] nvram customization
 * nvram customization
 *
 * Feb 19 2009 mtk80306
 * [DUMA00109277] add meta _battery mode.
 * add cap id
 *
 * Dec 17 2008 mbj08139
 * [DUMA00105099] create meta code
 * 
 *
 * Dec 8 2008 mbj08139
 * [DUMA00105099] create meta code
 * 
 *
 * Nov 24 2008 mbj08139
 * [DUMA00105099] create meta code
 * 
 *
 * Oct 29 2008 mbj08139
 * [DUMA00105099] create meta code
 * 
 *
 *******************************************************************************/



#ifndef _CFG_BT_D_H
#define _CFG_BT_D_H

///#include "../cfgfileinc/CFG_BT_File.h"

// the default value of bt nvram file
#if defined(MTK_MT6611) || defined(MTK_MT6612) || defined(MTK_MT6616) 
ap_nvram_btradio_mt6610_struct stBtDefault =
{
    {0x00, 0x00, 0x46, 0x66, 0x11, 0x01},
    {0x40},
    {0x23}
};
#elif defined(MTK_MT6620)
ap_nvram_btradio_mt6610_struct stBtDefault =
{
    {0x00, 0x00, 0x46, 0x66, 0x20, 0x01},
    {0x60, 0x00},
    {0x23, 0x10, 0x00, 0x00},
    {0x06, 0x80, 0x00, 0x06, 0x03, 0x06},
    {0x03, 0x40, 0x1F, 0x40, 0x1F, 0x00, 0x04},
    {0x80, 0x00},
    {0xFF, 0xFF, 0xFF}
};
#else
ap_nvram_btradio_mt6610_struct stBtDefault =
{
#if defined(MTK_MT6622)
    {0x00, 0x00, 0x46, 0x66, 0x22, 0x01}, /*addr*/
#else
    {0x00, 0x00, 0x46, 0x66, 0x26, 0x01}, /*addr*/
#endif
    {0x40}, /*CapId*/
    {0x01}, /*LinkKeyType*/
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},	/*UintKey*/
    {0x00, 0x02, 0x10}, /*Encryption*/
    {0x00}, /*PinCodeType*/
    {0x60, 0x00}, /*Voice*/
    {0x23, 0x00, 0x00, 0x00}, /*Codec*/
    {0x06, 0x80, 0x00, 0x06, 0x03, 0x06}, /*Radio */
    {0x03, 0x40, 0x1F, 0x40, 0x1F, 0x00, 0x04}, /*Sleep*/
    {0x80, 0x00}, /*BtFTR*/
    {0xFF, 0xFF, 0xFF}, /*TxPWOffset*/
    {0x00}, /*ECLK_SEL[1]*/
    {0x00}, /*Reserved1[1]*/
    {0x00, 0x00}, /*Reserved2[2]*/
    {0x00, 0x00, 0x00, 0x00}, /*Reserved3[4]*/
    {0x00, 0x00, 0x00, 0x00}, /*Reserved4[4]*/
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, /*Reserved5[16]*/
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, /*Reserved6[16]*/
};
#endif

#endif

