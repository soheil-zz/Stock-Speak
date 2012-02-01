#import "iDrinkViewController.h"
#import "Reachability.h"
#import "FBConnect.h"
#import <Twitter/Twitter.h>

@implementation iDrinkViewController

@synthesize topField, label1, label2, flipLabel;
@synthesize flipButton, facebookButton, tweetButton, typeButton, speakButton, ideasButton, menuViewController, tabBar, menuTableView;
@synthesize label = _label, facebook = _facebook;

static NSString* kAppId = @"116669421761762";

#define RECORDER_FILE_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/recording.caf"]
#define MAX_COUNT_BEFORE_PAY 15

/**
 * initialization
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (!kAppId) {
        NSLog(@"missing app id!");
        exit(1);
        return nil;
    }
    
    
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        _permissions =  [[NSArray arrayWithObjects:
                          @"read_stream", @"publish_stream", @"offline_access",nil] retain];
    }
    
    return self;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if ([[item title] isEqualToString:@"Type"]) {
        [self startType:nil];
    } else
    if ([[item title] isEqualToString:@"Speak"]
        && ![recorder isRecording]) {
        [self startSpeak];
    } else
    if ([[item title] isEqualToString:@"Ideas?"]) {
        [self feedback:nil];
        [self dehighlightTabBar];
    } else
    if ([[item title] isEqualToString:@"Cocktail Menu"]) {
        [self presentModalViewController:menuViewController animated:YES];
        [self dehighlightTabBar];
    }
}

- (void) dehighlightTabBar
{
    self.tabBar.selectedItem = nil;
}

- (IBAction) menuViewClose:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void) startRecording
{
    // only when currently offline try a 2nd time to see if we're online now
    if (!isOnline && !(isOnline = [self isDataSourceAvailable])) {
        NSLog(@"down");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:
                    @"You are not connected to the Internet, please go online and try again." 
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        topField.text = @"Please try again";
        
        [alert show];
        [alert release];
        
        return;
    }
    
    //AudioServicesPlaySystemSound (cling1); 
    [NSTimer scheduledTimerWithTimeInterval:.05
                                     target:self 
                                   selector:@selector(delayedRecording) 
                                   userInfo:nil 
                                    repeats:NO];
    //[self audioRecorderDidFinishRecording:nil successfully:true];
}

- (void) delayedRecording
{
    UIBarButtonItem *stopButton = [[UIBarButtonItem alloc] initWithTitle:@"Stop" style:UIBarButtonItemStyleBordered  target:self action:@selector(stopRecording)];
    self.navigationItem.rightBarButtonItem = stopButton;
    //[stopButton release];
    
    audioSession = [AVAudioSession sharedInstance];
    /*UInt32 ASRoute = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (
                             kAudioSessionProperty_OverrideAudioRoute,
                             sizeof (ASRoute),
                             &ASRoute
                             );*/
    /*UInt32 duck = 0;
    AudioSessionSetProperty(kAudioSessionProperty_OtherMixableAudioShouldDuck, sizeof(duck), &duck);
    AudioSessionSetActive(false);
    AudioSessionSetActive(true);*/
    
    NSError *err = nil;
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
    if(err){
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }
    [audioSession setActive:YES error:&err];
    err = nil;
    if(err){
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }
    
    recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey]; 
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    
    [recordSetting setValue :[NSNumber numberWithInt:128] forKey:AVEncoderBitRateKey];
    [recordSetting setValue :[NSNumber numberWithBool:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    [recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    
    
    
    // Create a new dated file
    //    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
    //    NSString *caldate = [now description];
    
    NSURL *url = [NSURL fileURLWithPath:RECORDER_FILE_PATH];
    err = nil;
    recorder = [[AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:&err];
    if(!recorder){
        NSLog(@"recorder: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle: @"Warning"
                                   message: [err localizedDescription]
                                  delegate: nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    //prepare to record
    [recorder setDelegate:self];
    [recorder prepareToRecord];
    recorder.meteringEnabled = YES;
    
    BOOL audioHWAvailable = audioSession.inputIsAvailable;
    if (! audioHWAvailable) {
        UIAlertView *cantRecordAlert =
        [[UIAlertView alloc] initWithTitle: @"Warning"
                                   message: @"Audio input hardware not available"
                                  delegate: nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
        [cantRecordAlert show];
        return;
    }
    
    // start recording
    [recorder recordForDuration:(NSTimeInterval) 1.7];
    
}

- (void) stopRecording{
    
    [recorder stop];
    
    NSURL *url = [NSURL fileURLWithPath: RECORDER_FILE_PATH];
    NSError *err = nil;
    NSData *audioData = [NSData dataWithContentsOfFile:[url path] options: 0 error:&err];
    if(!audioData)
        NSLog(@"audio data: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
    //[editedObject setValue:[NSData dataWithContentsOfURL:url] forKey:editedFieldKey];   
    
    //[recorder deleteRecording];
    
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    err = nil;
    [fm removeItemAtPath:[url path] error:&err];
    if(err)
        NSLog(@"File Manager: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
}

- (void)statusIsProcessing
{
    topField.text = @"...";
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
}

- (IBAction)userDoneEnteringText:(id)sender
{
    UITextField *theField = (UITextField*)sender;
    [theField resignFirstResponder];
    
    if ([theField.text length]) {
        [self makeRequestAndGetResults:FALSE];
    } else {
        theField.text = topFieldBeforeTypingStarted;
        flipButton.hidden = buttonsVisibilityBeforeTypingStarted;
        facebookButton.hidden = buttonsVisibilityBeforeTypingStarted;
        tweetButton.hidden = buttonsVisibilityBeforeTypingStarted;
    }
    
    
    [NSTimer scheduledTimerWithTimeInterval:.5
                                     target:self 
                                   selector:@selector(dehighlightTabBar) 
                                   userInfo:nil 
                                    repeats:NO];
}

- (BOOL) checkCount
{
    int count = [[NSUserDefaults standardUserDefaults] integerForKey:@"timesUsed"];
    if (count > MAX_COUNT_BEFORE_PAY) {
        [[[UIAlertView alloc] initWithTitle:@"Like This App?" message:@"You have run out of credits. In order to continue using this app please add more credits." delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Fill me up!", nil] show];
        
        return FALSE;
    }
    
    return TRUE;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // The first button (or cancel button)
    if (buttonIndex == 0) {
        return;
    }
    // The second button on the alert view
    if (buttonIndex == 1) {
        if ([inAppPurchaseManager canMakePurchases]) {
            [inAppPurchaseManager purchaseProUpgrade];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Cannot Make Purchase" message:@"Unable to add credits due to a payment issue." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil, nil] show];
        }
    }
}

- (IBAction)userStartedEnteringText:(id)sender
{
    if (![self checkCount]) {
        [topField resignFirstResponder];
        return;
    }
    
    // for both buttons
    buttonsVisibilityBeforeTypingStarted = flipButton.hidden;
    
    flipButton.hidden = YES;
    facebookButton.hidden = YES;
    tweetButton.hidden = YES;
    
    topFieldBeforeTypingStarted = [[NSString stringWithFormat:@"%@", topField.text] retain];
    
    // clear before entering text
    topField.text = @"";
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *) aRecorder successfully:(BOOL)flag
{
    NSError *err = nil;
    [audioSession setActive:NO error:&err];
    AudioServicesPlaySystemSound (cling2);
    
    [NSTimer scheduledTimerWithTimeInterval:.5
                                     target:self 
                                   selector:@selector(dehighlightTabBar) 
                                   userInfo:nil 
                                    repeats:NO];
    
    [self makeRequestAndGetResults:TRUE];
}

- (void) makeRequestAndGetResults:(BOOL)isAudio
{
    loadingView = [LoadingView loadingViewInView:self.view];
    NSLog (@"audioRecorderDidFinishRecording:successfully:");
    
    NSString *urlString = @"http://pubbay.com/pub/speech/drink.php";
    if (!isAudio) {
        urlString = [[urlString stringByAppendingString:@"?query="]
                     stringByAppendingString: [topField.text stringByAddingPercentEscapesUsingEncoding: NSASCIIStringEncoding]];
    }
    topField.text = @"...";
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    NSURL *url=[NSURL URLWithString:urlString];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    [request setTimeoutInterval:20.0];
    NSString *contentType = [NSString stringWithFormat:@"audio/x-flac; rate=44000"];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    if (isAudio) {
        NSData *fileData=[NSData dataWithContentsOfURL: [NSURL fileURLWithPath: RECORDER_FILE_PATH]];
        [request setHTTPBody:fileData];
    }
    
    NSError *errr=nil;
    NSURLResponse *resp=nil;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:&errr];
    NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    
    NSArray *lines = [returnString componentsSeparatedByString:@"||{}||"];
    
    if ([lines count] < 3) {
        topField.text = @"Please try again";
    } else {
        flipButton.hidden = NO;
        facebookButton.hidden = NO;
        tweetButton.hidden = NO;
        topField.text = [lines objectAtIndex:0];
        label1.text = [lines objectAtIndex:1];
        label2.text = [lines objectAtIndex:2];
        
        [self addDrinkToCocktailBook:topField.text];
        
        // ask for feedback
        [NSTimer scheduledTimerWithTimeInterval:1
                                         target:self 
                                       selector:@selector(requestFeedback) 
                                       userInfo:nil 
                                        repeats:NO];
        
        
        int count = [[NSUserDefaults standardUserDefaults] integerForKey:@"timesUsed"];
        [[NSUserDefaults standardUserDefaults] setInteger:++count forKey:@"timesUsed"];
        NSLog(@"%d", count);
    }
    
    NSLog(@"%@", returnString);
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    
	[loadingView
     performSelector:@selector(removeView)
     withObject:nil
     afterDelay:.1];
    
    
    typeButton.enabled = YES;
    speakButton.enabled = YES;
    ideasButton.enabled = YES;
}

- (void) loadOldDrinks
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSData *drinksData = [defs objectForKey: @"cocktailmenu"];
    if (drinksData == nil) {
        drinks = [[NSMutableArray alloc] init];
    } else {
        NSArray *oldDrinks = [NSKeyedUnarchiver unarchiveObjectWithData: drinksData];
        drinks = [[NSMutableArray alloc] initWithArray:oldDrinks];
    }    
}

- (void) addDrinkToCocktailBook:(NSString *)drinkName
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [self loadOldDrinks];
    BOOL found = FALSE;
    for(int i = 0; i < [drinks count]; i++) {
        if ([[drinks objectAtIndex:i] isEqualToString: drinkName]) {
            found = TRUE;
            break;
        }
    }
    if (!found) {
        [drinks addObject:drinkName];
    }
    if ([drinks count] > 25) {
        [drinks removeObjectAtIndex:0];
    }
    [defs setObject:[NSKeyedArchiver archivedDataWithRootObject:drinks] forKey:@"cocktailmenu"];
    [defs synchronize];
    
    [menuTableView removeFromSuperview];
    [menuTableView init];
}
/*- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellAccessoryDisclosureIndicator;
}*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 79.f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 25;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //[cell setNeedsDisplay];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if ([indexPath row] < [drinks count]) {
        int drinksIndex = [drinks count] - [indexPath row] - 1;
        cell.textLabel.text = [drinks objectAtIndex: drinksIndex];
        cell.tag = drinksIndex;
    } else {
        cell.textLabel.text = @"";
        cell.tag = -1;
    }
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([indexPath row] < [drinks count]) {
        topField.text = [drinks objectAtIndex: [drinks count] - [indexPath row] - 1];
        [self menuViewClose:nil];
        [NSTimer scheduledTimerWithTimeInterval:.05
                                         target:self 
                                       selector:@selector(makeRequestAndGetResultsDelayed) 
                                       userInfo:nil 
                                        repeats:NO];
    }
}

- (void)makeRequestAndGetResultsDelayed
{
    [self makeRequestAndGetResults:FALSE];
}

- (void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
}

/*
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // delete your data item here
        // remove the item from your data
        int drinksIndex = [drinks count] - [indexPath row] - 1;
        [drinks removeObjectAtIndex:drinksIndex];
        
        // Animate the deletion from the table.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    // refresh the table view
    [tableView reloadData];
}
*/
- (void) requestFeedback
{
    /*
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger daysSinceInstall = [[NSDate date] timeIntervalSinceDate:[defaults objectForKey:@"firstRun"]] / 86400;
    if (daysSinceInstall >= 0 || [defaults boolForKey:@"askedForRating"] == NO) {
        [[[UIAlertView alloc] initWithTitle:@"Like This App?" message:@"Please rate it in the App Store!" delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Rate It!", nil] show];
        [defaults setBool:YES forKey:@"askedForRating"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];*/
    
    [Appirater userDidSignificantEvent:YES];
}
/*
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		NSURL *url = [NSURL URLWithString:@"http://itunes.apple.com/us/app/idrink/id448067745?mt=8"];
		[[UIApplication sharedApplication] openURL:url];
	}
}
*/

- (IBAction) tweet
{
    if ([TWTweetComposeViewController canSendTweet])
    {
        TWTweetComposeViewController *tweetSheet = 
        [[TWTweetComposeViewController alloc] init];
        [tweetSheet setInitialText:[NSString stringWithFormat: @"I just made a #drink called \"%@\"!", topField.text]];
        [tweetSheet addURL:[NSURL URLWithString:
                            [NSString stringWithFormat: @"http://www.jog-a-lot.com/idrink/%@", 
                             [topField.text stringByReplacingOccurrencesOfString:@" " withString:@"+"]]]];
        [tweetSheet addImage:[UIImage imageNamed:@"Default.png"]];
        [self presentModalViewController:tweetSheet animated:YES];
        /*
        for(UIView *views in [tweetSheet.view subviews]) {
            for(UIView *view in [views subviews]) {
            if([view isKindOfClass:[UIButton class]]) {
                if([view tag] == 0) {
                    UIButton *btn = (UIButton *)view;
                    [btn sendActionsForControlEvents:UIControlEventTouchUpInside];
                    break;
                    NSLog(@"button");
                }
                else {
                    NSLog(@"didn't recognize tag");
                }
            } else {
                NSLog(@"view is not a button");
            }
            }}
        
        TWTweetComposeViewControllerCompletionHandler 
        completionHandler =
        ^(TWTweetComposeViewControllerResult result) {
            switch (result)
            {
                case TWTweetComposeViewControllerResultCancelled:
                    NSLog(@"Twitter Result: canceled");
                    break;
                case TWTweetComposeViewControllerResultDone:
                    NSLog(@"Twitter Result: sent");
                    break;
                default:
                    NSLog(@"Twitter Result: default");
                    break;
            }
            [self dismissModalViewControllerAnimated:YES];
        };
        [tweetSheet setCompletionHandler:completionHandler];
         */
    }    
}

- (void) requestTimedout
{
    topField.text = @"Please try again";
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

    [loadingView
     performSelector:@selector(removeView)
     withObject:nil
     afterDelay:.1];
}

- (void)delayedPlay
{
    /*
     ctl2 = [[MPMoviePlayerViewController alloc] initWithContentURL: videoURL];
     
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedPlaying:) name:MPMoviePlayerPlaybackDidFinishNotification object:[ctl2 moviePlayer]];
     //ctl.movieControlMode = MPMovieControlModeHidden;				
     
     player = [ctl2 moviePlayer];
     player.controlStyle = MPMovieControlStyleFullscreen;
     [self.view addSubview:ctl2.view];
     
     //[ctl setOrientation:UIDeviceOrientationLandscapeLeft animated:NO]; removing this caused the video to start playing audio			
     
     [player play];
     */
    /*player =[[MPMoviePlayerController alloc] initWithContentURL: videoURL];
     [[player view] setFrame: [self.view bounds]];
     [self.view addSubview: [player view]];*/
    
    /*[[NSNotificationCenter defaultCenter] addObserver:self 
     selector:@selector(finishedPlaying) 
     name:MPMoviePlayerPlaybackDidFinishNotification 
     object:player];*/
    
    //[player setControlStyle:MPMovieControlStyleFullscreen];
    //[player setMovieSourceType:MPMovieSourceTypeStreaming];
    //[player setFullscreen:YES];
    
    //[player play];
    /*
     // Create custom movie player   
     moviePlayer = [[CustomMoviePlayerViewController alloc] initWithPath:videoURL.path];
     
     // Show the movie player as modal
     [self presentModalViewController:moviePlayer animated:YES];
     
     // Prep and play the movie
     [moviePlayer readyPlayer]; */
}

- (void)finishedPlaying
{
    //NSLog(@"removeFromSuperview");
    //[player.view removeFromSuperview];
}

- (IBAction)startSpeak
{
    if (![self checkCount]) {
        return;
    }
    
    flipButton.hidden = YES;
    facebookButton.hidden = YES;
    tweetButton.hidden = YES;
    
    typeButton.enabled = NO;
    speakButton.enabled = NO;
    ideasButton.enabled = NO;
    
    topField.text = @"OK";
    label1.text = @"";
    label2.text = @"";
    [self startRecording];
}

- (IBAction)startType:(id)sender
{
    [topField becomeFirstResponder];
}

- (IBAction)feedback:(id)sender
{
//    [[ISFeedback sharedInstance] pushOntoViewController:self];
//    
//	[UserVoice presentUserVoiceModalViewControllerForParent:self
//													andSite:@"idrink.uservoice.com"
//													 andKey:@"vicsym4kaROR5ZKEkHBvzA"
//												  andSecret:@"iyKhWf8kr5H0c1j6DPN7ZXmgkmX9nLrzVz80sps"];
}

- (IBAction)flipView
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
    
    NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:@"FlipView"
                                                      owner:self
                                                    options:nil];
    
    flipView = [ nibViews objectAtIndex: 0];
    
    CGAffineTransform landscapeTransform = CGAffineTransformMakeRotation(3.14/2);
    landscapeTransform = CGAffineTransformTranslate (landscapeTransform, +90.0, +80.0);
    [flipView setTransform:landscapeTransform];
    
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:.3];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
						   forView:[self view]
							 cache:YES];
	[[self view] addSubview:flipView];
	[UIView commitAnimations];
    
    flipLabel.text = topField.text;
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    oldFrame = self.view.frame;
    CGRect newFrame = oldFrame;
    newFrame.size = CGSizeMake(360, 480);
    newFrame.origin = CGPointMake(-20, 0);
    self.view.frame = newFrame;
}

- (IBAction)unflipView
{
    self.view.frame = oldFrame;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
						   forView:[self view]
							 cache:YES];
	[flipView removeFromSuperview];
	[UIView commitAnimations];
}

- (BOOL)isDataSourceAvailable
{
    BOOL _isDataSourceAvailable = NO;
    
    Boolean success;    
    const char *host_name = "www.apple.com"; // your data source host name
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, host_name);
    SCNetworkReachabilityFlags flags;
    success = SCNetworkReachabilityGetFlags(reachability, &flags);
    _isDataSourceAvailable = success && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired);
    CFRelease(reachability);
    
    return _isDataSourceAvailable;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //[self startRecording];
    
    flipButton.hidden = YES;
    facebookButton.hidden = YES;
    tweetButton.hidden = YES;
    
    inAppPurchaseManager = [InAppPurchaseManager alloc];
    [inAppPurchaseManager loadStore];
    
    NSDictionary* env = [[NSProcessInfo processInfo] environment];
    
    if ([[env valueForKey:@"debug"] isEqual:@"TRUE"]) {
        NSLog(@"debugger yes");
        [[NSUserDefaults standardUserDefaults] setInteger:-10 forKey:@"timesUsed"];
    }
    else {
        NSLog(@"debugger no");
    }
    
//    [[TwitterAgent defaultAgent] twit:@"Share iDrink" withLink:@"http://www.jog-a-lot.com" makeTiny:NO];
    /*
    TwitterRequest *t = [[TwitterRequest alloc] init];
    t.username = @"suckstobeyou2";
    t.password = @"123456789";
    
    actionSheet = [[UIActionSheet alloc] initWithTitle:@"Posting to Twitter..." delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [actionSheet showInView:self.view];
    [t statuses_update:@"iDrink app rocks!" delegate:self requestSelector:@selector(statuses_updateCallback:)];
    */
    _facebook = [[Facebook alloc] initWithAppId:kAppId];
    [self.label setText:@"Please log in"];
    
    //    [self publishStream:nil];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
    
    
    // pre-loading only
    AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"cling_1" ofType:@"wav"]], &cling1);
    
    AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"cling_2" ofType:@"wav"]], &cling2);
    //AudioServicesPlaySystemSound (cling1);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (! [defaults objectForKey:@"firstRun"]) {
        [defaults setObject:[NSDate date] forKey:@"firstRun"];
    }
    
    [self loadOldDrinks];
    
    /*NSString *url = [[NSUserDefaults standardUserDefaults] stringForKey:@"url"];
    
    if (url) {
        topField.text = [url substringWithRange:NSMakeRange(1, url.length - 1)];
        [self makeRequestAndGetResults:FALSE];
    }*/
    
    /*NSArray *comp1 = [url componentsSeparatedByString:@"?"];
    NSString *query = [comp1 lastObject];
    NSArray *queryElements = [query componentsSeparatedByString:@"&"];
    for (NSString *element in queryElements) {
        NSArray *keyVal = [element componentsSeparatedByString:@"="];
        NSString *variableKey = [keyVal objectAtIndex:0];
        NSString *value = [keyVal lastObject];
        
        if ([variableKey isEqualToString:@"drink"]) {
        }
    }*/
}

- (void)statuses_updateCallback:(NSData *)content
{
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    [actionSheet release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    isOnline = [self isDataSourceAvailable];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}
/*
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
 {
 // Return YES for supported orientations
 if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
 return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
 } else {
 return YES;
 }
 }
 */

/**
 * Called when the user has logged in successfully.
 */
- (void)fbDidLogin {
    [self.label setText:@"logged in"];
    [self.label setText:@"Please log in"];
//    _getUserInfoButton.hidden = YES;
//    _getPublicInfoButton.hidden = YES;
//    _publishButton.hidden = YES;
//    _uploadPhotoButton.hidden = YES;
//    _fbButton.isLoggedIn = NO;
    [_fbButton updateImage];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (void)dealloc {
    [_label release];
    [_fbButton release];
    [_getUserInfoButton release];
    [_getPublicInfoButton release];
    [_publishButton release];
    [_uploadPhotoButton release];
    [_facebook release];
    [_permissions release];
    [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

/**
 * Show the authorization dialog.
 */
- (void)login {
    [_facebook authorize:_permissions delegate:self];
}

/**
 * Invalidate the access token and clear the cookie.
 */
- (void)logout {
    [_facebook logout:self];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// IBAction

/**
 * Called on a login/logout button click.
 */
- (IBAction)fbButtonClick:(id)sender {
    if (_fbButton.isLoggedIn) {
        [self logout];
    } else {
        [self login];
    }
}

/**
 * Make a Graph API Call to get information about the current logged in user.
 */
- (IBAction)getUserInfo:(id)sender {
    [_facebook requestWithGraphPath:@"me" andDelegate:self];
}


/**
 * Make a REST API call to get a user's name using FQL.
 */
- (IBAction)getPublicInfo:(id)sender {
    NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    @"SELECT uid,name FROM user WHERE uid=4", @"query",
                                    nil];
    [_facebook requestWithMethodName:@"fql.query"
                           andParams:params
                       andHttpMethod:@"POST"
                         andDelegate:self];
}

/**
 * Open an inline dialog that allows the logged in user to publish a story to his or
 * her wall.
 */
- (IBAction)publishStream:(id)sender {
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            kAppId, kAppId,
            [NSString stringWithFormat: @"http://www.jog-a-lot.com/idrink/%@", topField.text], @"link",
            @"http://www.jog-a-lot.com/idrink-small.gif", @"picture",
            @"Free iDrink iPhone app", @"name",
            @"Share Your Drink", @"caption",
            [NSString stringWithFormat: @"OMG! I just found out how to make a \"%@\" on iDrink app.", topField.text], @"description",
            [NSString stringWithFormat: @"I just made a drink called \"%@\"!", topField.text], @"message",
                                   nil];
    
    [_facebook dialog:@"feed" andParams:params andDelegate:self];
    /*
    SBJSON *jsonWriter = [[SBJSON new] autorelease];
    
    NSDictionary* actionLinks = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           @"Always Running",@"text",@"http://itsti.me/",@"href", nil], nil];
    
    NSString *actionLinksStr = [jsonWriter stringWithObject:actionLinks];
    NSDictionary* attachment = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"a long run", @"name",
                                @"The Facebook Running app", @"caption",
                                @"it is fun", @"description",
                                @"http://itsti.me/", @"href", nil];
    NSString *attachmentStr = [jsonWriter stringWithObject:attachment];
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"Share on Facebook",  @"user_message_prompt",
                                   actionLinksStr, @"action_links",
                                   attachmentStr, @"attachment",
                                   @"hi", @"message",
                                   nil];
    
    
    [_facebook dialog:@"feed"
            andParams:params
          andDelegate:self];*/
}

/**
 * Upload a photo.
 */
- (IBAction)uploadPhoto:(id)sender {
    NSString *path = @"http://www.facebook.com/images/devsite/iphone_connect_btn.jpg";
    NSURL *url = [NSURL URLWithString:path];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *img  = [[UIImage alloc] initWithData:data];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   img, @"picture",
                                   nil];
    
    [_facebook requestWithGraphPath:@"me/photos"
                          andParams:params
                      andHttpMethod:@"POST"
                        andDelegate:self];
    
    [img release];
}

/**
 * Called when the user canceled the authorization dialog.
 */
-(void)fbDidNotLogin:(BOOL)cancelled {
    NSLog(@"did not login");
}

/**
 * Called when the request logout has succeeded.
 */
- (void)fbDidLogout {
    [self.label setText:@"Please log in"];
    _getUserInfoButton.hidden    = YES;
    _getPublicInfoButton.hidden   = YES;
    _publishButton.hidden        = YES;
    _uploadPhotoButton.hidden = YES;
    _fbButton.isLoggedIn         = NO;
    [_fbButton updateImage];
}


////////////////////////////////////////////////////////////////////////////////
// FBRequestDelegate

/**
 * Called when the Facebook API request has returned a response. This callback
 * gives you access to the raw response. It's called before
 * (void)request:(FBRequest *)request didLoad:(id)result,
 * which is passed the parsed response object.
 */
- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"received response");
}

/**
 * Called when a request returns and its response has been parsed into
 * an object. The resulting object may be a dictionary, an array, a string,
 * or a number, depending on the format of the API response. If you need access
 * to the raw response, use:
 *
 * (void)request:(FBRequest *)request
 *      didReceiveResponse:(NSURLResponse *)response
 */
- (void)request:(FBRequest *)request didLoad:(id)result {
    if ([result isKindOfClass:[NSArray class]]) {
        result = [result objectAtIndex:0];
    }
    if ([result objectForKey:@"owner"]) {
        [self.label setText:@"Photo upload Success"];
    } else {
        [self.label setText:[result objectForKey:@"name"]];
    }
};

/**
 * Called when an error prevents the Facebook API request from completing
 * successfully.
 */
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    [self.label setText:[error localizedDescription]];
};


////////////////////////////////////////////////////////////////////////////////
// FBDialogDelegate

/**
 * Called when a UIServer Dialog successfully return.
 */
- (void)dialogDidComplete:(FBDialog *)dialog {
    [self.label setText:@"publish successfully"];
}
@end
