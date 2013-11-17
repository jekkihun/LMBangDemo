
#ifndef MP3_ALG_H
#define MP3_ALG_H

#ifdef __cplusplus
extern "C" {
#endif




typedef struct
{
	short  num_channels;         
	int    in_samplerate;      
	short  brate;    
}T_mp3CodecParam;



/* �����ʼ������ */
extern short mp3EncoderInit(T_mp3CodecParam *pParams);    

/* �����ʼ������ */
extern short mp3DecoderInit(T_mp3CodecParam *pParams);    


/* ����������     */
extern short mp3EncoderProc(unsigned int  *pwInputPnt,				  
								   short  pwInputSize,
						   unsigned char  *pcOutputPnt, 
								   short  *pcOutSize);

    						

/* ����������     */
extern short mp3DecoderProc(unsigned char  *pcInputPnt, 
					                short  pcInputSize,
                                    short  *pwOutputPntL, 
			                        short  *pwOutputPntR, 
                                    short  *pwOutSize);


			


#ifdef __cplusplus
}
#endif

#endif
