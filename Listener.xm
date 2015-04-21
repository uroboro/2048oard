#include <dlfcn.h>
#include <objc/runtime.h>
#include <dispatch/dispatch.h>
#import <libactivator/libactivator.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

#include "interfaces.h"
#import "functions.h"

#import "_2048oard.h"
#import "SB2048IconView.h"
#import "SB2048Icon.h"

static NSString *bundleID = @"com.uroboro.2048oard";

static LAActivator *_LASharedActivator;

static void loadActivator() {
	NSLog(@"X2048:: attempting to load libactivator");
	void *la = dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	if (!(char *)la) {
		NSLog(@"X2048:: failed to load libactivator");
	}
	_LASharedActivator = [objc_getClass("LAActivator") sharedInstance];
}

@implementation _2048oard

+ (id)sharedInstance {
	static id sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedInstance = [self new];
	});
	return sharedInstance;
}

+ (void)load {
	loadActivator();
	[self sharedInstance];
}

- (id)init {
	if ([super init]) {
		// Register our listener
		if (_LASharedActivator) {
			NSLog(@"X2048:: libactivator is installed");
			if (![_LASharedActivator hasSeenListenerWithName:bundleID]) {
				[_LASharedActivator assignEvent:[%c(LAEvent) eventWithName:@"libactivator.volume.both.press"] toListenerWithName:bundleID];
			}
			if (_LASharedActivator.isRunningInsideSpringBoard) {
				[_LASharedActivator registerListener:self forName:bundleID];
			}
		}
/*
		[[NSNotificationCenter defaultCenter] addObserver:self
			selector:@selector(springboardDidFinishLaunching:)
			name:UIApplicationDidFinishLaunchingNotification
			object:nil];
*/
	}
	return self;
}

- (void)dealloc {
	if (_LASharedActivator) {
		if (_LASharedActivator.runningInsideSpringBoard) {
			[_LASharedActivator unregisterListenerWithName:bundleID];
		}
	} 
	[super dealloc];
}

// Notification callbacks

- (void)springboardDidFinishLaunching:(NSNotification *)notification {
	SB2048Icon *icon = [%c(SB2048Icon) new];
	SBIconController *ic = [%c(SBIconController) sharedInstance];
	[ic addNewIconToDesignatedLocation:icon animate:NO scrollToList:NO saveIconState:NO];
	SB2048IconView *iconView = [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
	icon.value = 2048;
	if (kCFCoreFoundationVersionNumber <= 800) { // < iOS 7
		[iconView updateLabel];
	} else {
		[iconView _updateLabel];
	}
}

// Listener main methods

- (void)show {
	_showing = YES;

	SBIconController *ic = [%c(SBIconController) sharedInstance];
	CGFloat folderTime = 0;
	if ([ic hasOpenFolder]) {
		_folderToOpen = [ic openFolder];
		[ic closeFolderAnimated:YES];
		folderTime = 0.5;
	}

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, folderTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[self present];
	});
}

- (void)present {
	[self concealIcons];

	_board = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	[_board setWindowLevel:UIWindowLevelStatusBar-2];
	[_board setAutoresizesSubviews:YES];
	[_board setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
	[_board setHidden:NO];

	_overlay = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	[_overlay setWindowLevel:UIWindowLevelStatusBar-1];
	[_overlay setAutoresizesSubviews:YES];
	[_overlay setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];

	for (UISwipeGestureRecognizerDirection d = UISwipeGestureRecognizerDirectionRight; d <= UISwipeGestureRecognizerDirectionDown; d <<= 1) {
		UISwipeGestureRecognizer *sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
		sgr.direction = d;
		sgr.delegate = self;
		[_overlay addGestureRecognizer:sgr];
	}
	UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
	tgr.numberOfTouchesRequired = 2;
	tgr.delegate = self;
	[_overlay addGestureRecognizer:tgr];

	[_overlay makeKeyAndVisible];

	[self spawnNewGame];
}

- (void)dismiss {
	_showing = NO;

	if (_board) {
		for (UIView *v in _board.subviews) {
			[self unpopupView:v];
		}
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[_board setHidden:YES];
		});
		[_board release];
		_board = nil;
	}

	if (_preview) {
		[self saveGame];
		_preview = nil;
	}

	if (_overlay) {
		[_overlay setHidden:YES];
		[_overlay release];
		_overlay = nil;
	}

	[self revealIcons];

	if (_folderToOpen) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[[%c(SBIconController) sharedInstance] openFolder:_folderToOpen animated:YES];
			_folderToOpen = nil;
		});
	}
}

- (void)processTurnWithDirection:(UISwipeGestureRecognizerDirection)direction {
	NSMutableArray *newValues = [processArrayWithDirection(_preview, direction) mutableCopy];
	if (![newValues isEqualToArray:_preview]) {
		addRandomValueToArray(newValues);
		[self updateBoard];
/* Placeholder for popup animation for inserted icons (instead of popping up all of them)
		[newValues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if (![obj isEqual:_preview[idx]]) {
				//this is not the correct index for the subview, gotta recalculate
//				[self popupView:_board.subviews[idx]];
				[self popupView:_board.subviews[0]];
			}
		}];
*/
	}
	_preview = newValues;
	[self updateBoard];

	BOOL b = canMakeMovements(_preview);
	if (!b) {
		// Present end screen
		[self showGameOverScreen];
		[self deleteGame];
	}
}

- (void)updateBoard {
	if (!_board) {
		return;
	}
	for (UIView *v in _board.subviews) {
		[v removeFromSuperview];
	}

	if (!_preview) {
		return;
	}
	[_preview enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if (![obj intValue]) {
			return;
		}

		SB2048IconView *v = [[%c(SB2048IconView) alloc] initWithDefaultSize];
		v.icon = [%c(SB2048Icon) new];
		((SB2048Icon *)v.icon).value = [obj intValue];
		if (kCFCoreFoundationVersionNumber <= 800) { // < iOS 7
			[v updateLabel];
		} else {
			[v _updateLabel];
		}
		v.frame = frameForPosition(positionForIndex(idx));
		[_board addSubview:v];
		[self popupView:v];
		[v release];
	}];
}

- (void)spawnNewGame {
	[self loadGame];
	[self updateBoard];
}

- (void)showGameOverScreen {
	CGRect f = frameForPosition(3, 3);
	CGFloat h = f.origin.y + f.size.height + 16;
	CGSize goss = CGSizeMake(_board.frame.size.width, h);

	_gameOverScreen = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _board.frame.size.width, h)];
	_gameOverScreen.backgroundColor = [UIColor colorWithRed:255/255.0f green:219/255.0f blue:118/255.0f alpha:1.0f];
	_gameOverScreen.alpha = 0.0;

	UILabel* gameOverLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, goss.width * 0.8, goss.height)];
	gameOverLabel.center = CGPointMake(_gameOverScreen.center.x, (goss.height / 16) * 5);
	gameOverLabel.backgroundColor = [UIColor clearColor];
	gameOverLabel.text = @"Game Over!";
	gameOverLabel.textColor = [UIColor colorWithRed:255/255.0f green:94/255.0f blue:29/255.0f alpha:1.0f];
	gameOverLabel.font = [UIFont boldSystemFontOfSize:72];
	gameOverLabel.adjustsFontSizeToFitWidth = YES;
	gameOverLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	[_gameOverScreen addSubview:gameOverLabel];
	[gameOverLabel release];

	UILabel *scoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, goss.width*0.6, goss.height)];
	scoreLabel.center = CGPointMake(_gameOverScreen.center.x, (goss.height / 8) * 4);
	scoreLabel.backgroundColor = [UIColor clearColor];
	scoreLabel.text = [NSString stringWithFormat:@"You reached %d!", highestNumberInArray(_preview)];
	scoreLabel.textColor = [UIColor colorWithRed:255/255.0f green:94/255.0f blue:29/255.0f alpha:1.0f];
	scoreLabel.font = [UIFont systemFontOfSize:64];
	scoreLabel.adjustsFontSizeToFitWidth = YES;
	scoreLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	[_gameOverScreen addSubview:scoreLabel];
	[scoreLabel release];

	UIButton *tryAgainButton = [UIButton buttonWithType:UIButtonTypeCustom];
	tryAgainButton.frame = CGRectMake(0, 0, goss.width / 3, goss.height / 6);
	tryAgainButton.center = CGPointMake(goss.width / 4, goss.height * 0.75);
	tryAgainButton.backgroundColor = [UIColor lightGrayColor];
	tryAgainButton.layer.borderColor = [UIColor grayColor].CGColor;
	tryAgainButton.layer.borderWidth = 0.5f;
	tryAgainButton.layer.cornerRadius = 20.0f;
	tryAgainButton.clipsToBounds = YES;
	[tryAgainButton addTarget:self action:@selector(spawnNewGameFromSender:) forControlEvents:UIControlEventTouchUpInside];
	[tryAgainButton setTitle:@"Try Again" forState:UIControlStateNormal];
	[tryAgainButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[_gameOverScreen addSubview:tryAgainButton];

	UIButton *quitButton = [UIButton buttonWithType:UIButtonTypeCustom];
	quitButton.frame = CGRectMake(0, 0, goss.width / 3, goss.height / 6);
	quitButton.center = CGPointMake((goss.width / 4) * 3, goss.height * 0.75);
	quitButton.backgroundColor = [UIColor lightGrayColor];
	quitButton.layer.borderColor = [UIColor grayColor].CGColor;
	quitButton.layer.borderWidth = 0.5f;
	quitButton.layer.cornerRadius = 20.0f;
	quitButton.clipsToBounds = YES;
	[quitButton addTarget:self action:@selector(act) forControlEvents:UIControlEventTouchUpInside];
	[quitButton setTitle:@"Exit" forState:UIControlStateNormal];
	[quitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[_gameOverScreen addSubview:quitButton];

	[_overlay addSubview:_gameOverScreen];

	[UIView animateWithDuration:0.75 animations:^{
		_gameOverScreen.alpha = 1.0;
	}];
}

- (void)spawnNewGameFromSender:(UIButton *)button {
	if (!_gameOverScreen) {
		return;
	}
	[UIView animateWithDuration:0.5 animations:^{
		_gameOverScreen.alpha = 0.0;
	} completion:^(BOOL finished){
		if (finished) {
			[_gameOverScreen removeFromSuperview];
			[_gameOverScreen release];
			_gameOverScreen = nil;
			[self spawnNewGame];
		}
	}];
}

// SpringBoard SBIconView hide/reveal

- (void)setIconViewsAlpha:(CGFloat)a {
	SBIconController *ic = (SBIconController *)[%c(SBIconController) sharedInstance];
	NSArray *icons = [[ic currentRootIconList] icons];
	[icons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		SBIcon *icon = (SBIcon *)obj;
		UIView *iconView = [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
		[UIView animateWithDuration:0.2 animations:^{
			[iconView setAlpha:a];
		}];
	}];
}

- (void)concealIcons {
	[self setIconViewsAlpha:0];
}

- (void)revealIcons {
	[self setIconViewsAlpha:1];
}

// Game state management

- (NSString *)saveGamePath {
	return [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", bundleID];
}

- (void)loadGame {
	NSString *path = [self saveGamePath];
	if (0&&[[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:path];
		_preview = [d objectForKey:@"saveGameKey"];
	} else {
		_preview = randomArrayOf16Numbers();
	}
}

- (void)saveGame {
	if (0&&_preview) {
		NSDictionary *d = @{@"saveGameKey":_preview};
		[d writeToFile:[self saveGamePath] atomically:YES];
	}
}

- (void)deleteGame {
	NSString *path = [self saveGamePath];
	if (0&&[[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSError *e = nil;
		if (![[NSFileManager defaultManager] removeItemAtPath:path error:&e]) {
			NSLog(@"Error deleting file: %@", e);
		}
	}
	_preview = nil;
}

// Animations

- (void)popupView:(UIView *)view {
	view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.001, 0.001);
	[UIView animateWithDuration:0.3/1.5 animations:^{
		view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.3/2 animations:^{
			view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:0.3/2 animations:^{
				view.transform = CGAffineTransformIdentity;
			}];
		}];
	}];
}

- (void)unpopupView:(UIView *)view {
	view.transform = CGAffineTransformIdentity;
	[UIView animateWithDuration:0.3/2 animations:^{
		view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.3/2 animations:^{
			view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:0.3/1.5 animations:^{
				view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.001, 0.001);
			}];
		}];
	}];
}

// _overlay's gestureRecognizer methods

- (void)handleSwipeGesture:(UISwipeGestureRecognizer *)gestureRecognizer {
	[self processTurnWithDirection:gestureRecognizer.direction];
}

- (void)handlePanGesture:(UITapGestureRecognizer *)gestureRecognizer {
	[self dismiss];
}

// UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	return YES;
}

// LAListener protocol methods

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	// Called when we receive event
	if (!_showing) {
		[self show];
	} else {
		[self dismiss];
	}
	[event setHandled:YES];
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event {
	// Called when event is escalated to a higher event
	// (short-hold sleep button becomes long-hold shutdown menu, etc)
	[self dismiss];
}

- (void)activator:(LAActivator *)activator otherListenerDidHandleEvent:(LAEvent *)event {
	// Called when some other listener received an event; we should cleanup
	[self dismiss];
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event {
	// Called when the home button is pressed.
	// If (and only if) we are showing UI, we should dismiss it and call setHandled:
	[self dismiss];
}

// Metadata
// Group name
- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
	return @"Games";
}
// Listener name
- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
	return @"2048";
}
// Listener description
- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
	return @"Play 2048 on SB";
}
/* Group assignment filtering
- (NSArray *)activator:(LAActivator *)activator requiresExclusiveAssignmentGroupsForListenerName:(NSString *)listenerName {
	return [NSArray array];
}
*/

@end
