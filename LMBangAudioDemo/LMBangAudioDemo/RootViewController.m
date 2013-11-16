//
//  RootViewController.m
//  LMBangAudioDemo
//
//  Created by Kzzang's Macbook on 13-11-16.
//  Copyright (c) 2013年 Kzzang's Macbook. All rights reserved.
//

#import "RootViewController.h"
#import <AVFoundation/AVFoundation.h>

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
        NSError *error = [self  playWithUrl:self.recordPathURL];
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
                                         AVEncoderAudioQualityKey: @(AVAudioQualityMax),
                                         AVNumberOfChannelsKey: @2,
                                         AVSampleRateKey: @44100,
                                         AVLinearPCMIsBigEndianKey :@NO,
                                         AVLinearPCMIsFloatKey: @NO,
                                         AVLinearPCMBitDepthKey :@16,
                                         AVEncoderBitRateKey: @16000};
        
        //create FileName
        NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
        [formatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString *uniqueName = [NSString stringWithFormat:@"lmbang_%@.lpcm",[formatter stringFromDate:[NSDate date]]];
        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"recordFile"];
        
        NSError *createDirError = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&createDirError];
        path = [path stringByAppendingPathComponent:uniqueName];
        NSLog(@"Will be record file path = %@",path);
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
    
    if (!self.recordPathURL) {
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
