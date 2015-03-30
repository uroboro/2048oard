#include <objc/runtime.h>
#include <dispatch/dispatch.h>
#import <libactivator/libactivator.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

#include "interfaces.h"

#define indexForPosition_(row, column, columnsPerRow) (row * columnsPerRow + column)
#define indexForPosition(row, column) indexForPosition_(row, column, 4)
#define positionForIndex(idx) idx/4, idx%4

static NSString *bundleID = @"com.uroboro.2048oard";

@interface _2048oard : NSObject <LAListener, UIGestureRecognizerDelegate> {
}
@property (nonatomic, retain) NSMutableArray *preview;

// UI
@property (nonatomic, assign) BOOL showing;
@property (nonatomic, retain) UIWindow *overlay;
@property (nonatomic, retain) UIWindow *board;

@property (nonatomic, assign) id folderToOpen;

+ (id)sharedInstance;

- (void)show;
- (void)dismiss;
- (BOOL)act;

@end

#if 1 /* SB2048Icon */

@implementation NSObject (SB2048Icon)

- (BOOL)is2048Icon {
	return NO;
}

@end

@interface SB2048Icon : SBIcon
@property (nonatomic, assign) NSInteger value;
- (UIImage *)imageFromView:(UIView *)view;
- (UIView *)getIconView:(int)image;
- (UIColor *)colorForValue:(NSInteger)value;
@end

%subclass SB2048Icon : SBIcon

- (BOOL)is2048Icon {
	return YES;
}

%new
- (NSInteger)value {
	NSNumber *n = objc_getAssociatedObject(self, _cmd);
	return [n intValue];
}

%new
- (void)setValue:(NSInteger)value {
	objc_setAssociatedObject(self, @selector(value), @(value), OBJC_ASSOCIATION_ASSIGN);
	[self reloadIconImagePurgingImageCache:0];
}

%new
- (UIColor *)colorForValue:(NSInteger)value {
	static NSMutableDictionary *notSoExplicitColors = [NSMutableDictionary new];
	if (!notSoExplicitColors.count) {
		CGFloat frequency = 1.0 / 16;
		for (NSInteger i = 0; i < 16; i++) {
				CGFloat r = 0.5 + 0.5 * cos(2 * M_PI * frequency * i + 0 * M_PI / 3);
				CGFloat g = 0.5 + 0.5 * cos(2 * M_PI * frequency * i + 4 * M_PI / 3);
				CGFloat b = 0.5 + 0.5 * cos(2 * M_PI * frequency * i + 2 * M_PI / 3);
			[notSoExplicitColors setObject:[UIColor colorWithRed:r green:g blue:b alpha:1] forKey:@(2 << i)];
		}
	}

	UIColor *c = [notSoExplicitColors objectForKey:@(value)];
	return c ? c : [UIColor whiteColor];
}

%new
- (UIImage *)imageFromView:(UIView *)view {
	UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
	[view.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return img;
}

%new
- (UIView *)getIconView:(int)image {
	CGSize s = [%c(SBIconView) defaultIconImageSize];

	UIView *view = [[UIView alloc] initWithFrame:CGRectInset(CGRectMake(0, 0, s.width, s.height), 2, 2)];
	view.opaque = NO;
	view.backgroundColor = [self colorForValue:self.value];
	view.layer.cornerRadius = 15;
	view.layer.masksToBounds = YES;

	UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectInset(view.frame, 5, 5)];
	valueLabel.backgroundColor = [UIColor clearColor];
	valueLabel.textColor = [UIColor lightGrayColor];
	valueLabel.text = [NSString stringWithFormat:@"%d", self.value];
	valueLabel.font = [UIFont systemFontOfSize:valueLabel.frame.size.height];
	valueLabel.adjustsFontSizeToFitWidth = YES;
	valueLabel.textAlignment = NSTextAlignmentCenter;
	valueLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	[view addSubview:valueLabel];
	[valueLabel release];

	return [view autorelease];
}

- (UIImage *)getIconImage:(int)image {
	return [self imageFromView:[self getIconView:image]];
}

- (UIImage *)getGenericIconImage:(int)image {
	return [self imageFromView:[self getIconView:image]];
}

- (UIImage *)generateIconImage:(int)image {
	return [self imageFromView:[self getIconView:image]];
}

- (UIImage *)getStandardIconImageForLocation:(int)location {
	return [self imageFromView:[self getIconView:location]];
}

- (NSString *)displayName {
	return [NSString stringWithFormat:@"%d", self.value];
}

- (BOOL)canEllipsizeLabel {
	return NO;
}

- (NSString *)folderFallbackTitle {
	return @"2048";
}

- (NSString *)applicationBundleID {
	return [@"2048-" stringByAppendingString:[self displayName]];
}

- (Class)iconViewClassForLocation:(int)location {
	return %c(SB2048IconView);
}

#if 1 /* Figure out how to make the app use this class to prevent the SBUserInstalledApplicationIcon hook below */
-(void)launch {
	[[_2048oard sharedInstance] act];
}

- (void)launchFromViewSwitcher {
	[[_2048oard sharedInstance] act];
}

- (void)launchFromLocation:(int)arg1 {
	[[_2048oard sharedInstance] act];
}
#endif /* Figure out how to make the app use this class to prevent the SBUserInstalledApplicationIcon hook below */

%end

@interface SBUserInstalledApplicationIcon : SBIcon @end

%hook SBUserInstalledApplicationIcon

-(void)launch {
	if ([self.applicationBundleID isEqualToString:bundleID]) {
		[[_2048oard sharedInstance] act];
	} else {
		%orig();
	}
}

- (void)launchFromViewSwitcher {
	if ([self.applicationBundleID isEqualToString:bundleID]) {
		[[_2048oard sharedInstance] act];
	} else {
		%orig();
	}
}

- (void)launchFromLocation:(int)arg1 {
	if ([self.applicationBundleID isEqualToString:bundleID]) {
		[[_2048oard sharedInstance] act];
	} else {
		%orig();
	}
}

%end

#endif /* SB2048Icon */

#if 1 /* SB2048IconView */

@interface SB2048IconView : SBIconView
@end

%subclass SB2048IconView : SBIconView

- (id)initWithDefaultSize {
	if ((self = %orig())) {
	}
	return self;
}

- (NSString *)accessibilityValue {
	return [self.icon displayName];
}

- (NSString *)accessibilityHint {
	return [self.icon displayName];
}

%end

#endif /* SB2048IconView */

static CGRect frameForPosition(NSInteger row, NSInteger column) {
	CGSize s = [%c(SBIconView) defaultIconSize];
	int offsets[4] = {0, 1, 3, 4};
	int xPadding = ([[UIApplication sharedApplication] keyWindow].frame.size.width - 4 * s.width) / 5;
	int yPadding = 16;

	CGFloat x = xPadding + (xPadding + s.width) * column + offsets[column];
	CGFloat y = yPadding + (yPadding + s.height) * row;

	return CGRectMake(x, y, s.width, s.height);
}

static NSArray *arraysWithDirection(NSArray *array, UISwipeGestureRecognizerDirection direction) {
	if (!array) {
		return nil;
	}

	NSInteger xm, xM, xd, ym, yM, yd;
	NSInteger xy; // first loop is for x
	switch (direction) {
	case UISwipeGestureRecognizerDirectionRight:
		//top to bottom, 0 at right
		xy = 0;
		ym = 0; yM = 4; yd = 1;
		xm = 3; xM = -1; xd = -1;
	break;
	case UISwipeGestureRecognizerDirectionLeft:
		//top to bottom, 0 at left
		xy = 0;
		ym = 0; yM = 4; yd = 1;
		xm = 0; xM = 4; xd = 1;
	break;
	case UISwipeGestureRecognizerDirectionUp:
		//left to right, 0 at top
		xy = 1;
		ym = 0; yM = 4; yd = 1;
		xm = 0; xM = 4; xd = 1;
	break;
	case UISwipeGestureRecognizerDirectionDown:
		//left to right, 0 at bottom
		xy = 1;
		ym = 3; yM = -1; yd = -1;
		xm = 0; xM = 4; xd = 1;
	break;
	default:
		return nil;
	}

	NSMutableArray *a = [NSMutableArray new];
	NSInteger x, y;
	for ((!xy ? (y = ym) : (x = xm)); (!xy ? (y != yM) : (x != xM)); y += !xy * yd, x +=  xy * xd) {
		NSMutableArray *temp = [NSMutableArray new];
		for (( xy ? (y = ym) : (x = xm)); ( xy ? (y != yM) : (x != xM)); y +=  xy * yd, x += !xy * xd) {
			[temp addObject:array[indexForPosition(y, x)]];
		}
		[a addObject:temp];
		[temp release];
	}

	return [a autorelease];
}

static NSArray *sinkIcons(NSArray *icons) {
	if (!icons) {
		return nil;
	}

	NSMutableArray *array = [icons mutableCopy];
	int c = array.count - 1;
	for (int j = 0; j < c; j++) {
		for (int i = 0; i < c - j; i++) {
			if (![array[i] intValue]) {
				id obj = array[i];
				array[i] = array[i+1];
				array[i+1] = obj;
			}
		}
	}

	return array;
}

static NSArray *compressedArrayIfNeeded(NSArray *icons) {
	if (!icons) {
		return nil;
	}
	//initial sort
	//move all zero/null values to the end of the array
	NSArray *array = sinkIcons(icons);

	NSMutableArray *compressedIcons = [NSMutableArray new];
	NSInteger c = array.count;
	for (int i = 0; i < c; i++) {
		NSInteger currValue = [array[i] intValue];

		// Skip if current value is 0
		if (!currValue) {
			continue;
		}

		NSInteger nextValue = (i + 1 >= c) ? 0 : [array[i+1] intValue];

		// Add current value if next is 0 or doesn't exist
		if (!nextValue) {
			[compressedIcons addObject:@(currValue)];
			continue;
		}

		// Compress if equal
		if (currValue == nextValue) {
			[compressedIcons addObject:@(currValue * 2)];
			[compressedIcons addObject:@0];
			i++;
			continue;
		}

		// Just add if they differ
		[compressedIcons addObject:@(currValue)];
	}

	//sort the items
	//using the above, we will retain zeroes in the middle of the sequence
	//we want 4 4 0 0, not 4 0 4 0
	//move zeroes to the end again
	NSMutableArray *result = [sinkIcons(compressedIcons) mutableCopy];
	[compressedIcons release];
	//ensure we always return 4 items
	while (result.count < 4) {
		[result addObject:@0];
	}

	return result;
}

static NSArray *sinkedArraysWithDirection(NSArray *array, UISwipeGestureRecognizerDirection direction) {
	NSArray *arrays = arraysWithDirection(array, direction);
	if (!arrays) {
		return nil;
	}
	NSMutableArray *result = [NSMutableArray new];
	for (NSArray *array in arrays) {
		[result addObject:compressedArrayIfNeeded(array)];
	}
	return [result autorelease];
}

static NSArray *composedArrayWithDirection(NSArray *array, UISwipeGestureRecognizerDirection direction) {
	if (!array) {
		return nil;
	}

	NSInteger xm, xM, xd, ym, yM, yd;
	NSInteger xy; // first loop is for x
	switch (direction) {
	case UISwipeGestureRecognizerDirectionRight:
		//top to bottom, 0 at right
		xy = 0;
		ym = 0; yM = 4; yd = 1;
		xm = 3; xM = -1; xd = -1;
	break;
	case UISwipeGestureRecognizerDirectionLeft:
		//top to bottom, 0 at left
		xy = 0;
		ym = 0; yM = 4; yd = 1;
		xm = 0; xM = 4; xd = 1;
	break;
	case UISwipeGestureRecognizerDirectionUp:
		//left to right, 0 at top
		xy = 1;
		ym = 0; yM = 4; yd = 1;
		xm = 0; xM = 4; xd = 1;
	break;
	case UISwipeGestureRecognizerDirectionDown:
		//left to right, 0 at bottom
		xy = 1;
		ym = 0; yM = 4; yd = 1;
		xm = 3; xM = -1; xd = -1;
	break;
	default:
		return nil;
	}

	NSMutableArray *a = [NSMutableArray new];
	NSInteger x, y;
	for ((!xy ? (y = ym) : (x = xm)); (!xy ? (y != yM) : (x != xM)); y += !xy * yd, x +=  xy * xd) {
		for (( xy ? (y = ym) : (x = xm)); ( xy ? (y != yM) : (x != xM)); y +=  xy * yd, x += !xy * xd) {
			[a addObject:array[y][x]];
		}
	}

	return [a autorelease];
}

static NSArray *processArrayWithDirection(NSArray *array, UISwipeGestureRecognizerDirection direction) {
	NSArray *arrays = sinkedArraysWithDirection(array, direction);
	return composedArrayWithDirection(arrays, direction);
}

static void addRandomValueToArray(NSMutableArray *array) {
	if (!array) {
		return;
	}

	NSInteger iconsToPlace = 1 + ((array.count < 12) && (arc4random_uniform(100) >= 35));

	for (int i = 0; i < iconsToPlace; i++) {
		//find out how many zero values they have so we can determine random range
		//we store their indexes in an array so we don't have to find the index later
		NSMutableArray *zeroTracker = [NSMutableArray new];

		[array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if (![obj intValue]) {
				[zeroTracker addObject:@(idx)];
			}
		}];

		//place a random icon at a random one of the null values
		NSNumber *zeroIndex = zeroTracker[arc4random_uniform(zeroTracker.count)];
		NSInteger newValue = 2 << (arc4random_uniform(4) == 3);

		[array replaceObjectAtIndex:[zeroIndex intValue] withObject:@(newValue)];
		[zeroTracker release];
	}
}

static NSMutableArray *randomArrayOf16Numbers() {
	NSMutableArray *array = [NSMutableArray new];
	for (int i = 0; i < 16; i++) {
		NSInteger j = arc4random_uniform(10);
		NSInteger newValue = (j < 7) ? 0 : (j < 9) ? 2 : 4;
		[array addObject:@(newValue)];
	}
	return array;
}

static NSInteger highestNumberInArray(NSArray *array) {
	__block NSInteger i = 0;
	[array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSInteger value = [(NSNumber *)obj intValue];
		if (value > i) {
			i = value;
		}
	}];
	return i;
}

static BOOL canMakeMovements(NSArray *array) {
	NSArray *aRight = processArrayWithDirection(array, UISwipeGestureRecognizerDirectionRight);
	NSArray *aLeft = processArrayWithDirection(array, UISwipeGestureRecognizerDirectionLeft);
	NSArray *aUp = processArrayWithDirection(array, UISwipeGestureRecognizerDirectionUp);
	NSArray *aDown = processArrayWithDirection(array, UISwipeGestureRecognizerDirectionDown);
	BOOL c0 = [aRight isEqualToArray:aLeft];
	BOOL c1 = [aUp isEqualToArray:aDown];
	return !((c0 && c1) ? [aRight isEqualToArray:aUp] : NO);
}

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

- (void)hideIcons {
	[self setIconViewsAlpha:0];
}

- (void)revealIcons {
	[self setIconViewsAlpha:1];
}

- (NSString *)saveGamePath {
	return [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", bundleID];
}

- (void)loadGame {
	NSString *path = [self saveGamePath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		_preview = [NSArray arrayWithContentsOfFile:path];
	}
}

- (void)saveGame {
	NSString *path = [self saveGamePath];
	if (_preview) {
		[_preview writeToFile:path atomically:YES];
	}
}

- (void)deleteGame {
	NSString *path = [self saveGamePath];
	NSError *e = nil;
	if (![[NSFileManager defaultManager] removeItemAtPath:path error:&e]) {
		NSLog(@"Error deleting file: %@", e);
	}
	_preview = nil;
}

- (void)show {
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

- (void)dismiss {
	if (_board) {
		[_board setHidden:YES];
		[_board release];
		_board = nil;
	}

	if (_overlay) {
		[_overlay setHidden:YES];
		[_overlay release];
		_overlay = nil;
	}

}

- (BOOL)act {
	// Ensures alert view is dismissed
	// Returns YES if alert was visible previously
	SBIconController *ic = [%c(SBIconController) sharedInstance];

	if (!_showing) {
		_showing = YES;

		CGFloat folderTime = 0;
		if ([ic hasOpenFolder]) {
			_folderToOpen = [ic openFolder];
			[ic closeFolderAnimated:YES];
			folderTime = 0.5;
		}

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, folderTime * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self hideIcons];
			[self show];
		});
	} else {
		_showing = NO;
		[self dismiss];
		[self revealIcons];

		if (_folderToOpen) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				[ic openFolder:_folderToOpen animated:YES];
				_folderToOpen = nil;
			});
		}
	}
	return _showing;
}

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

- (void)showGameOverScreen {
	CGRect f = frameForPosition(3, 3);
	CGFloat h = f.origin.y + f.size.height + 16;
	UIView *gameOverScreen = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _board.frame.size.width, h)];
	gameOverScreen.backgroundColor = [UIColor colorWithRed:255/255.0f green:219/255.0f blue:118/255.0f alpha:1.0f];
	gameOverScreen.alpha = 0.0;

	CGSize goss = gameOverScreen.frame.size;

	UILabel* gameOverLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, goss.width * 0.8, goss.height)];
	gameOverLabel.center = CGPointMake(gameOverScreen.center.x, (goss.height / 16) * 5);
	gameOverLabel.text = @"Game Over!";
	gameOverLabel.textColor = [UIColor colorWithRed:255/255.0f green:94/255.0f blue:29/255.0f alpha:1.0f];
	gameOverLabel.font = [UIFont boldSystemFontOfSize:72];
	gameOverLabel.adjustsFontSizeToFitWidth = YES;
	gameOverLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	[gameOverScreen addSubview:gameOverLabel];

	UILabel *scoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, goss.width*0.6, goss.height)];
	scoreLabel.center = CGPointMake(gameOverScreen.center.x, (goss.height / 8) * 4);
	scoreLabel.text = [NSString stringWithFormat:@"You reached %d!", highestNumberInArray(_preview)];
	scoreLabel.textColor = [UIColor whiteColor];
	scoreLabel.font = [UIFont systemFontOfSize:64];
	scoreLabel.adjustsFontSizeToFitWidth = YES;
	scoreLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	[gameOverScreen addSubview:scoreLabel];

	UIButton *tryAgainButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[tryAgainButton addTarget:self action:@selector(spawnNewGameFromSender:) forControlEvents:UIControlEventTouchUpInside];
	[tryAgainButton setTitle:@"Try Again" forState:UIControlStateNormal];
	[tryAgainButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	tryAgainButton.backgroundColor = [UIColor lightGrayColor];
	tryAgainButton.frame = CGRectMake(0, 0, goss.width / 3, goss.height / 6);
	tryAgainButton.center = CGPointMake(goss.width / 4, goss.height * 0.75);
	tryAgainButton.layer.borderColor = [UIColor grayColor].CGColor;
	tryAgainButton.layer.borderWidth = 0.5f;
	tryAgainButton.layer.cornerRadius = 20.0f;
	tryAgainButton.clipsToBounds = YES;
	[gameOverScreen addSubview:tryAgainButton];

	//we use the buttons layer to pass the game over screen to that method
	//so it can be removed
	[[tryAgainButton layer] setValue:gameOverScreen forKey:@"screen"];

	UIButton *quitButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[quitButton addTarget:self action:@selector(act) forControlEvents:UIControlEventTouchUpInside];
	[quitButton setTitle:@"Exit" forState:UIControlStateNormal];
	[quitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	quitButton.backgroundColor = [UIColor lightGrayColor];
	quitButton.frame = CGRectMake(0, 0, goss.width / 3, goss.height / 6);
	quitButton.center = CGPointMake((goss.width / 4) * 3, goss.height * 0.75);
	quitButton.layer.borderColor = [UIColor grayColor].CGColor;
	quitButton.layer.borderWidth = 0.5f;
	quitButton.layer.cornerRadius = 20.0f;
	quitButton.clipsToBounds = YES;
	[gameOverScreen addSubview:quitButton];

	[_overlay addSubview:gameOverScreen];

	[UIView animateWithDuration:0.75 animations:^{
		gameOverScreen.alpha = 1.0;
	}];
}

- (void)spawnNewGameFromSender:(UIButton *)button {
	UIView *gameOverScreen = [[button layer] valueForKey:@"screen"];
	[UIView animateWithDuration:0.5 animations:^{
		gameOverScreen.alpha = 0.0;
	} completion:^(BOOL finished){
		if (finished) {
			[gameOverScreen removeFromSuperview];
			[self spawnNewGame];
		}
	}];
}

- (void)spawnNewGame {
	_preview = randomArrayOf16Numbers();
	[self updateBoard];
}

- (void)handleSwipeGesture:(UISwipeGestureRecognizer *)gestureRecognizer {
	UISwipeGestureRecognizerDirection dir = gestureRecognizer.direction;

	NSArray *procValues = processArrayWithDirection(_preview, dir);
	[self updateBoard];

	NSMutableArray *newValues = [procValues mutableCopy];
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
	}
}

- (void)handlePanGesture:(UITapGestureRecognizer *)gestureRecognizer {
	[self act];
}

// UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	return YES;
}

// LAListener protocol methods

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	// Called when we receive event
	if ([self act]) {
		[event setHandled:YES];
	}
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event {
	// Called when event is escalated to a higher event
	// (short-hold sleep button becomes long-hold shutdown menu, etc)
	_showing = YES;
	[self act];
}

- (void)activator:(LAActivator *)activator otherListenerDidHandleEvent:(LAEvent *)event {
	// Called when some other listener received an event; we should cleanup
	_showing = YES;
	[self act];
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event {
	// Called when the home button is pressed.
	// If (and only if) we are showing UI, we should dismiss it and call setHandled:
	_showing = YES;
	[self act];
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
