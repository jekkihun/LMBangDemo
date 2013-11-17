//
//  RootViewController.m
//  LMBangAudioDemo
//
//  Created by Kzzang's Macbook on 13-11-16.
//  Copyright (c) 2013年 Kzzang's Macbook. All rights reserved.
//

#import "RootViewController.h"
#import <AVFoundation/AVFoundation.h>

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <memory.h>

#include "ns.h"
#include "mp3_alg.h"

#define L 160
#define FRAME (1152/2)
#define MAXMP3BUFFER   720*2 //16384

// noise suppress procedure
extern void NoiseSupp(short *farray_ptr);
// .wav filehead struct
typedef struct{
	char WRIFF[4];
	long W08Size;
	char WWAVE[4];
	char Wfmt[4];
	long WPCM;
	short int  WC1;
	short int  WChanel;
	long WSampleRate;
	long WSamplespersecond;
	short int  WBytenumber;
	short int  WResolution;
	char Wdata[4];
	long WSize;
}WavFileHeader;

#define kIOS7_OR_LATER      ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)


@interface RootViewController ()<AVAudioRecorderDelegate, AVAudioPlayerDelegate> {
    NSTimeInterval startRecordTime;
    NSTimeInterval stopRecordTime;
}

@property (nonatomic, retain) AVAudioRecorder *recorder;
@property (nonatomic, retain) AVAudioPlayer *player;
@property (nonatomic, retain) NSURL *recordPathURL;
@property (nonatomic, retain) UIButton *recordButton;
@property (nonatomic, retain) UIButton *playButton;
@property (nonatomic, retain) UILabel  *recordDescLabel;
@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, retain) NSString *fileConvertToPath;
@property (nonatomic, retain) NSString *convertMp3FilePath;

@end

@implementation RootViewController

#pragma mark - Memory Managment Method
- (void)dealloc
{
    [_recordPathURL release];
    [_recorder release];
    [_player release];
    [_recordButton release];
    [_recordDescLabel release];
    [_playButton release];
    [_filePath release];
    [_fileConvertToPath release];
    [_convertMp3FilePath release];
    [super dealloc];
}

#pragma mark - Init
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - InitViews

- (void) initViews {

    CGFloat offset = kIOS7_OR_LATER ? 64.0f : 44.0f;

    
    UIView *bkgView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.size.height - 49.0f - offset, self.view.frame.size.width, 49.0f)];
    [bkgView setBackgroundColor:[UIColor blackColor]];
    bkgView.alpha = 0.8;

    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [doneButton.titleLabel setFont:[UIFont boldSystemFontOfSize:12.]];
    [doneButton setTitle:@"开始录音" forState:UIControlStateNormal];
    [doneButton setFrame:CGRectMake(10.0f, 10.0f, 50.0f, 30.0f)];
    [doneButton addTarget:self action:@selector(record) forControlEvents:UIControlEventTouchUpInside];
    [doneButton.layer setMasksToBounds:YES];
    [doneButton.layer setCornerRadius:4.0];
    [doneButton.layer setBorderWidth:1.0];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef colorref = CGColorCreate(colorSpace,(CGFloat[]){ 1, 1, 1, 1 });
    [doneButton.layer setBorderColor:colorref];
    doneButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [bkgView addSubview:doneButton];
    self.recordButton = doneButton;
    
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [playButton.titleLabel setFont:[UIFont boldSystemFontOfSize:12.]];
    [playButton setTitle:@"开始播放" forState:UIControlStateNormal];
    [playButton setFrame:CGRectMake(320.0f - 60.0f, 10.0f, 50.0f, 30.0f)];
    [playButton addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    [playButton.layer setMasksToBounds:YES];
    [playButton.layer setCornerRadius:4.0];
    [playButton.layer setBorderWidth:1.0];
    [playButton.layer setBorderColor:colorref];
    playButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [bkgView addSubview:playButton];
    self.playButton = playButton;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    [titleLabel setFrame:CGRectMake((320.f- 60.0f)/2, 10.0f, 200.0f, 40.0f)];
    [titleLabel setCenter:CGPointMake(160.0f, 25.0f)];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:10.0f]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    titleLabel.text = @"";
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [bkgView addSubview:titleLabel];
    self.recordDescLabel = titleLabel;
    
    [self.view addSubview:bkgView];

    [titleLabel release];
    [doneButton release];
    [bkgView release];
}


#pragma mark - Actions

- (void) play {

    if ([self.player isPlaying]) {
        [self.playButton setTitle:@"开始播放" forState:UIControlStateNormal];
        [self stop];
    } else {
        NSError *error = [self  playWithUrl:[NSURL fileURLWithPath:self.convertMp3FilePath]];
        if (error) {
            
            NSString *errorMessage = [NSString stringWithFormat:@"Error:%@",error];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:errorMessage delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [alert release];
            return;
        }
        [self.playButton setTitle:@"停止播放" forState:UIControlStateNormal];
        self.recordDescLabel.text = @"正在播放....";
        
    }
    
}

- (void) record {
    
    if ([self.recorder isRecording]) {
        [self.recordButton setTitle:@"开始录音" forState:UIControlStateNormal];
        [self stopRecord];
    } else {
        [self.recordButton setTitle:@"停止录音" forState:UIControlStateNormal];
        NSError *error = [self startRecord];
        if (error) {
            
            NSString *errorMessage = [NSString stringWithFormat:@"Error:%@",error];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误" message:errorMessage delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
        self.recordDescLabel.text = @"正在录音....";
    }


}

#pragma mark - Audio Record
- (NSError *) startRecord {
    
    NSError *error = NULL;
    
    if (!self.recorder) {
        NSError *sesstionError = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&sesstionError];
        
        if (sesstionError) {
            return sesstionError;
        }
        //        NSMutableDictionary *recordSetting = [NSMutableDictionary dictionary];
        //        [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
        //        [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
        //        [recordSetting setValue:[NSNumber numberWithInt:8] forKey:AVLinearPCMBitDepthKey];
        //        [recordSetting setValue:[NSNumber numberWithInt:25600] forKey:AVEncoderBitRateKey];
        //        [recordSetting setValue:[NSNumber numberWithInt:8] forKey:AVEncoderBitDepthHintKey];
        //        [recordSetting setValue:[NSNumber numberWithInt:8] forKey:AVEncoderBitRatePerChannelKey];
        //        [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
        //        [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
        //        [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
        
        
        
        /*
        // 辣妈帮正在使用的录制设置
        NSDictionary *recordSettings = @{AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                         AVEncoderAudioQualityKey: @(AVAudioQualityMin),
                                         AVNumberOfChannelsKey: @1,
                                         AVSampleRateKey: @16000,
                                         AVLinearPCMIsBigEndianKey :@NO,
                                         AVLinearPCMIsFloatKey: @NO,
                                         AVLinearPCMBitDepthKey :@16,
                                         AVEncoderBitRateKey: @16000};
         */
        
        
        // AVFormatIDKey          - PCM
        // AVSampleRateKey        - 采样率
        // AVNumberOfChannelsKey  - 通道数目
        // AVLinearPCMBitDepthKey - 采样位数
        // AVLinearPCMIsFloatKey  - 采样信号是整数还是浮点数
        NSDictionary *recordSettings = @{AVFormatIDKey: @(kAudioFormatLinearPCM),
                                         AVEncoderAudioQualityKey: @(AVAudioQualityMin),
                                         AVNumberOfChannelsKey: @1,
                                         AVSampleRateKey: @16000,
                                         AVLinearPCMIsBigEndianKey :@NO,
                                         AVLinearPCMIsFloatKey: @NO,
                                         AVLinearPCMBitDepthKey :@16};
         
         /*
        NSDictionary *recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                       [NSNumber numberWithFloat: 8000.0],AVSampleRateKey, //采样率
                                       [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                                       [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,//采样位数 默认 16
                                       [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,//通道的数目
                                       //                                   [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,//大端还是小端 是内存的组织方式
                                       //                                   [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,//采样信号是整数还是浮点数
                                       //                                   [NSNumber numberWithInt: AVAudioQualityMedium],AVEncoderAudioQualityKey,//音频编码质量
                                       nil];
        */
        //create FileName
        NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
        [formatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString *uniqueName = [NSString stringWithFormat:@"lmbang_%@.wav",[formatter stringFromDate:[NSDate date]]];
        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"recordFile"];
        
        {
            NSString *uniqueName = [NSString stringWithFormat:@"lmbang_%@_rs.wav",[formatter stringFromDate:[NSDate date]]];
            NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"recordFile"];
            self.fileConvertToPath = [path stringByAppendingPathComponent:uniqueName];
        
        }
        
        {
            NSString *uniqueName = [NSString stringWithFormat:@"lmbang_%@_rs.mp3",[formatter stringFromDate:[NSDate date]]];
            NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"recordFile"];
            self.convertMp3FilePath = [path stringByAppendingPathComponent:uniqueName];
            
        }
        
        NSError *createDirError = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&createDirError];
        path = [path stringByAppendingPathComponent:uniqueName];
        NSLog(@"Will be record file path = %@",path);
        self.filePath = path;
        self.recordPathURL = [NSURL fileURLWithPath:path];
        
        AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:self.recordPathURL settings:recordSettings error:&error];
        if (error) {
            NSLog(@"error: %@",error);
            [recorder release];
            return error;
        }
        
        
        [recorder recordForDuration:60.0f];
        [recorder setMeteringEnabled:YES];
        [recorder setDelegate:self];
        self.recorder = recorder;
        [recorder release];
        
    }
    
    // Start Record
    if ([self.recorder prepareToRecord]) {
        [self.recorder record];
        NSLog(@"开始录音");
        startRecordTime = [[NSDate date] timeIntervalSince1970];

    } else {
        NSLog(@"Record Error!");
        self.recorder.delegate = nil;
        self.recorder = nil;
        return [NSError errorWithDomain:@"chat.lmbang.com" code:280000 userInfo:nil];
    }
    
    return nil;
}

- (void) stopRecord {
    if ([self.recorder isRecording]) {
        self.recorder.delegate = nil;
        NSLog(@"停止录音");
        [self.recorder stop];
        [self recordFinished];
        
    } else {
        NSLog(@"已经停止录音");
    }
    
}

- (void) recordFinished {
    stopRecordTime = [[NSDate date] timeIntervalSince1970];
    // 记录录音时常，四舍五入
    NSInteger recordTime = round(stopRecordTime - startRecordTime);

    // 计算文件大小
    NSData *recordFile = [NSData dataWithContentsOfURL:self.recordPathURL];
    NSLog(@"recordFile Length = %d KB and record time = %d",recordFile.length / 1024,recordTime);
    self.recordDescLabel.text = [NSString stringWithFormat:@"文件大小：%dKB 录音时长：%d 秒",recordFile.length / 1024,recordTime];
    [self.recordButton setTitle:@"开始录音" forState:UIControlStateNormal];

    [self convert];
    [self converToMp3];
    //清除对象
    self.recorder = nil;
}

#pragma mark - Audio Player

- (void) stop {
    [self.player stop];
    self.player.delegate = nil;
    self.player = nil;
    self.recordDescLabel.text = @"开始播放";
}

- (NSError *) playWithUrl:(NSURL *) url {
    
    if (!self.convertMp3FilePath) {
        return [NSError errorWithDomain:@"找不到文件路径，请先录音！" code:-12 userInfo:nil];
    }
    
    
    if ([self.player isPlaying]) {
        [self stop];
    }
    //初始化播放器的时候如下设置
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                            sizeof(sessionCategory),
                            &sessionCategory);
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
                             sizeof (audioRouteOverride),
                             &audioRouteOverride);
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    
    
    NSError *error = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    NSLog(@"初始化播放器：播放文件目录= %@",url);
    if (error) {
        NSLog(@"error: %@",error);
        [player release];
        player = nil;
        return error;
    }
    
    player.numberOfLoops = 0;
    player.delegate = self;
    NSLog(@"准备播放");
    if ([player prepareToPlay]) {
        NSLog(@"开始播放");
        [player play];
    } else {
        NSLog(@"准备播放失败");
        return [NSError errorWithDomain:@"chat.lmbang.com" code:290000 userInfo:nil];
    }
    self.player = player;
    [player release];
    return nil;
}


#pragma mark - Convert
- (void) convert {
	WavFileHeader head;
	short int readbuf[L];
    
	//char fname1[256] = "/Users/apple/Documents/nsevrc_testlib/test16k.wav";        // degraded speech
	//char fname2[256] = "/Users/apple/Documents/nsevrc_testlib/test16k_ns.wav";        // filted speech
    
    
    //self.filePath = [[NSBundle mainBundle] pathForResource:@"test16k" ofType:@"wav"];
    const char *fname1 = [self.filePath UTF8String];
    const char *fname2 = [self.fileConvertToPath UTF8String];

	FILE *fp1, *fp2, *logFile;
    
	if((fp1=fopen(fname1,"rb")) == NULL){
		printf("\nCann't open %s", fname1);
		//exit(0);
	}
   	if((fp2=fopen(fname2,"wb")) == NULL){
		printf("\nCann't open %s", fname2);
		//exit(0);
	}
    
    printf("\n --- Running ---\n");
    
	fread(&head,sizeof(WavFileHeader),1,fp1);
	fwrite(&head,sizeof(WavFileHeader),1,fp2);
	fseek(fp1,sizeof(WavFileHeader),SEEK_SET);
    
	while(!feof(fp1)){
		fread(&readbuf[0],sizeof(short),L,fp1);
		
		NoiseSupp(&readbuf[0]);
		fwrite(&readbuf[0],sizeof(short),L,fp2);
	}
    printf("\n --- END ---\n");
    
	fclose(fp1);
	fclose(fp2);
}

- (void) converToMp3 {
    WavFileHeader head;
    
    FILE *f_speech = NULL;                 /* File of speech data                   */
    FILE *f_serial = NULL;                 /* File of serial bits for transmission  */
    
    
    //   short pcm_l[1152],pcm_r[1152];
    unsigned char mp3buffer[MAXMP3BUFFER];
    unsigned short     Buffer[1152];
    int k=1;
    
    T_mp3CodecParam CodecParam;
    
    short length, pack_len;
    short frame = 0;
    short err = 0, iread;
    short max = 0;
    
    const char *pin_name = [self.fileConvertToPath UTF8String];
    const char *pout_name = [self.convertMp3FilePath UTF8String];
    
    /*
     * Open speech file and result file (output serial bit stream)
     */
    if ((f_speech = fopen(pin_name, "rb")) == NULL)
        printf("Can't open pin_name.pcm !\n"), err++;
    
    if ((f_serial = fopen(pout_name, "w+b")) == NULL)
        printf("Can't open pout_name.pcm !\n" ), err++;
    
    
	fread(&head,sizeof(WavFileHeader),1,f_speech);
    
    /*
     * Initialisation
     */
	CodecParam.num_channels = 1; //mono
	CodecParam.in_samplerate = 16000; //Hz
	CodecParam.brate = 32; //32kbps
    
	//pack_len = (CodecParam.brate*1000*FRAME)/(CodecParam.in_samplerate*8);
    
	mp3EncoderInit(&CodecParam);
	
    printf("\n --- Running ---\n");
    
    frame = 0;
    
    
    while ((iread = fread(Buffer, sizeof(unsigned short), FRAME, f_speech)) != 0)//int
    {
        
        frame++;
        printf(" \n Frames processed: %hd\r", frame);
        
        /* encode */
        mp3EncoderProc(Buffer, iread,	mp3buffer, &length);
        
        fwrite(mp3buffer, 1, length, f_serial);
        
    }
    printf("\n --- END ---\n");
    
    fclose(f_speech);
    fclose(f_serial);
}


#pragma mark - Viewcontroller Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationItem.title = @"辣妈帮录音DEMO";
    [self initViews];
    
    NSLog(@"self view frame = %@",NSStringFromCGRect(self.view.frame));
}

#pragma mark - AVAudioRecorderDelegate

/* audioRecorderDidFinishRecording:successfully: is called when a recording has been finished or stopped. This method is NOT called if the recorder is stopped due to an interruption. */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [self recordFinished];
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
}

/* audioRecorderBeginInterruption: is called when the audio session has been interrupted while the recorder was recording. The recorded file will be closed. */
- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
}

/* audioRecorderEndInterruption:withOptions: is called when the audio session interruption has ended and this recorder had been interrupted while recording. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withFlags:(NSUInteger)flags{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
}

/* audioRecorderEndInterruption: is called when the preferred method, audioRecorderEndInterruption:withFlags:, is not implemented. */
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
}

#pragma mark - AVAudioPlayer Delegate Methods
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
    NSLog(@"%s",__FUNCTION__);
}
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags {
    NSLog(@"%s",__FUNCTION__);
}
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"%s",__FUNCTION__);
    [self stop];
    
}
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"%s",__FUNCTION__);
    NSLog(@"error: %@",error);
}

@end
