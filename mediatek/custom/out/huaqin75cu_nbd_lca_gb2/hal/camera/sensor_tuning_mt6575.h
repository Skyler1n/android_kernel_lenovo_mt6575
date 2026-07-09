#ifndef _SENSOR_TUNING_MT6575_H_
#define _SENSOR_TUNING_MT6575_H_

/*******************************************************************************
* Dynamic Frame Rate
*******************************************************************************/
DynamicFrameRate_T const&
getParamDynamicFrameRate()
{
    static DynamicFrameRate_T inst = { 
        EVTheshold      : 50,
        isEnableDFps    : false,
    };
    return inst;
}

/*******************************************************************************
* 
*******************************************************************************/
#endif //  _SENSOR_TUNING_MT6575_H_

