#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioServices.h>

#import "LoadingView.h"
#import "TwitterAgent.h"
#import "TwitterRequest.h"
#import "FBConnect.h"
#import "FBLoginButton.h"
#import "Appirater.h"
#import "InAppPurchaseManager.h"

@class Reachability;
@interface iDrinkViewController : UIViewController <AVAudioRecorderDelegate,
FBRequestDelegate,
FBDialogDelegate,
FBSessionDelegate,
UITabBarDelegate> {
    
    AVAudioRecorder *recorder;
    NSMutableDictionary *recordSetting;
    NSString *recorderFilePath;
    NSURL *videoURL;
    LoadingView *loadingView;
    BOOL isOnline;
    UIView *flipView;
    
    IBOutlet UILabel* _label;
    IBOutlet FBLoginButton* _fbButton;
    IBOutlet UIButton* _getUserInfoButton;
    IBOutlet UIButton* _getPublicInfoButton;
    IBOutlet UIButton* _publishButton;
    IBOutlet UIButton* _uploadPhotoButton;
    Facebook* _facebook;
    NSArray* _permissions;
    
    UIActionSheet *actionSheet;
    CGRect oldFrame;
    SystemSoundID cling1, cling2;
    AVAudioSession *audioSession;
    
    NSString *topFieldBeforeTypingStarted;
    BOOL buttonsVisibilityBeforeTypingStarted;
    
    NSMutableArray *drinks;
    
    InAppPurchaseManager *inAppPurchaseManager;
}

@property (nonatomic, retain) IBOutlet UITextField *topField;
@property (nonatomic, retain) IBOutlet UILabel *label1;
@property (nonatomic, retain) IBOutlet UITextView *label2;
@property (nonatomic, retain) IBOutlet UILabel *flipLabel;
@property (nonatomic, retain) IBOutlet UIButton *flipButton;
@property (nonatomic, retain) IBOutlet UIButton *facebookButton;
@property (nonatomic, retain) IBOutlet UIButton *tweetButton;
@property (nonatomic, retain) IBOutlet UIButton *typeButton;
@property (nonatomic, retain) IBOutlet UIButton *speakButton;
@property (nonatomic, retain) IBOutlet UIButton *ideasButton;
@property (nonatomic, retain) IBOutlet UITabBar *tabBar;
@property (nonatomic, retain) IBOutlet UITableView *menuTableView;
@property (nonatomic, retain) IBOutlet UIViewController *menuViewController;

@property(nonatomic, retain) UILabel* label;
@property(readonly) Facebook *facebook;

- (IBAction)startSpeak;
- (IBAction)flipView;
- (void)statusIsProcessing;
- (void)delayedPlay;
- (void) delayedRecording;
- (void)finishedPlaying;
- (BOOL)isDataSourceAvailable;
- (void) requestTimedout;
- (IBAction)userDoneEnteringText:(id)sender;
- (IBAction)userStartedEnteringText:(id)sender;
- (void) makeRequestAndGetResults:(BOOL)isAudio;
- (void) dehighlightTabBar;

-(IBAction)fbButtonClick:(id)sender;

-(IBAction)getUserInfo:(id)sender;

-(IBAction)getPublicInfo:(id)sender;

-(IBAction)publishStream:(id)sender;

-(IBAction)uploadPhoto:(id)sender;

- (void)statuses_updateCallback:(NSData *)content;
- (IBAction)feedback:(id)sender;
- (IBAction)startType:(id)sender;
- (IBAction)menuViewClose:(id)sender;

- (void) addDrinkToCocktailBook:(NSString *)drinkName;
- (IBAction) tweet;


@end
