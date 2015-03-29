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

#define FILE_OUTPUT 1

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
- (UIColor *)textColorForValue:(NSInteger)value;
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
- (UIColor *)textColorForValue:(NSInteger)value {
	//TODO fix these
	//TODO add more
	//le testing
	NSDictionary *explicitColors = @{
		@2:[UIColor redColor],
		@4:[UIColor orangeColor],
		@8:[UIColor yellowColor],
		@16:[UIColor greenColor],
		@32:[UIColor blueColor],
		@64:[UIColor purpleColor]
	};

	UIColor *c = [explicitColors objectForKey:@(value)];
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

	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, s.width, s.height)];
	view.opaque = NO;
	view.backgroundColor = [UIColor darkGrayColor];
	view.layer.cornerRadius = 15;
	view.layer.masksToBounds = YES;
//	view.alpha = 0.4;

	UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectInset(view.frame, 5, 5)];
	valueLabel.backgroundColor = [UIColor clearColor];
	valueLabel.textColor = [self textColorForValue:self.value];
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

- (Class)iconImageViewClassForLocation:(int)location {
	return %c(SB2048IconImageView);
}

%end
#endif /* SB2048Icon */

#if 1 /* SB2048IconView */
@interface SB2048IconView : SBIconView
@end

%subclass SB2048IconView : SBIconView

- (id)initWithDefaultSize {
	if ((self = %orig())) {
		SB2048Icon *i = [%c(SB2048Icon) new];
		self.icon = i;
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

#if 1 /* SB2048IconImageView */
@interface SB2048IconImageView : SBIconImageView
@end

%subclass SB2048IconImageView : SBIconImageView

- (void)updateImageAnimated:(BOOL)animated {
	%orig();
	//modify self.layer
}

%end
#endif /* SB2048IconImageView */

@interface _2048oard : NSObject <LAListener> {
}
@property (nonatomic, retain) NSMutableArray *currentLayout;
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

static NSString *NSArrayDescriptionInSingleLine(NSArray *a) {
	if (!a) {
		return nil;
	}
	return [NSString stringWithFormat:@"@[%@]", [a componentsJoinedByString:@","]];
}

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
//	printf("x:%d,%d,%d\n", xm, xd, xM);
//	printf("y:%d,%d,%d\n", ym, yd, yM);
//	printf("d:%d\n", direction);
	for ((!xy ? (y = ym) : (x = xm)); (!xy ? (y != yM) : (x != xM)); y += !xy * yd, x +=  xy * xd) {
		NSMutableArray *temp = [NSMutableArray new];
		for (( xy ? (y = ym) : (x = xm)); ( xy ? (y != yM) : (x != xM)); y +=  xy * yd, x += !xy * xd) {
//			printf("%d ", indexForPosition(y, x));
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
//	printf("x:%d,%d,%d\n", xm, xd, xM);
//	printf("y:%d,%d,%d\n", ym, yd, yM);
//	printf("d:%d\n", direction);
	for ((!xy ? (y = ym) : (x = xm)); (!xy ? (y != yM) : (x != xM)); y += !xy * yd, x +=  xy * xd) {
		for (( xy ? (y = ym) : (x = xm)); ( xy ? (y != yM) : (x != xM)); y +=  xy * yd, x += !xy * xd) {
//			printf("%d ", indexForPosition(y, x));
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

static BOOL canMakeMovements(NSArray *array) {
	NSArray *aRight = processArrayWithDirection(array, UISwipeGestureRecognizerDirectionRight);
	NSArray *aLeft = processArrayWithDirection(array, UISwipeGestureRecognizerDirectionLeft);
	NSArray *aUp = processArrayWithDirection(array, UISwipeGestureRecognizerDirectionUp);
	NSArray *aDown = processArrayWithDirection(array, UISwipeGestureRecognizerDirectionDown);
	BOOL c0 = [aRight isEqualToArray:aLeft];
	BOOL c1 = [aUp isEqualToArray:aDown];
	return !((c0 && c1) ? [aRight isEqualToArray:aUp] : NO);
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
	[self sharedInstance];
}

- (id)init {
	if ([super init]) {
		// Register our listener
		if (LASharedActivator.isRunningInsideSpringBoard) {
			[LASharedActivator registerListener:self forName:@"com.uroboro.2048oard"];
		}
	}
	return self;
}

- (void)dealloc {
	if (LASharedActivator.runningInsideSpringBoard) {
		[LASharedActivator unregisterListenerWithName:@"com.uroboro.2048oard"];
	}
	[super dealloc];
}

- (void)setIconViewsAlpha:(CGFloat)a {
	SBIconController *ic = (SBIconController *)[%c(SBIconController) sharedInstance];
	NSArray *icons = [[ic currentRootIconList] icons];
	[icons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		SBIcon *icon = (SBIcon *)obj;
		UIView *iconView = [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
		[iconView setAlpha:a];
	}];
}

- (void)hideIcons {
	[self setIconViewsAlpha:0];
}

- (void)revealIcons {
	[self setIconViewsAlpha:1];
}

- (void)show {
	[self hideIcons];

	_preview = randomArrayOf16Numbers();
	NSLog(@"\033[32mX_2048oard: %@\033[0m", NSArrayDescriptionInSingleLine(_preview));

#if FILE_OUTPUT
	FILE *fp = fopen("/User/2048oard.txt", "w");
	for (int j = 0; j < 16; j++) {
		fprintf(fp, "%d%c", [_preview[j] intValue], (j%4==3)?'\n':' ');
	}
	fclose(fp);
#endif /* FILE_OUTPUT */

	_board = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	[_board setWindowLevel:UIWindowLevelAlert-2];
	[_board setAutoresizesSubviews:YES];
	[_board setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];

	[self updateBoard];
	[_board setHidden:NO];

	_overlay = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	[_overlay setWindowLevel:UIWindowLevelAlert-1];
	[_overlay setAutoresizesSubviews:YES];
	[_overlay setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
#if DEBUG
	[_overlay setBackgroundColor:[UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.3]];
#endif
	for (UISwipeGestureRecognizerDirection d = UISwipeGestureRecognizerDirectionRight; d <= UISwipeGestureRecognizerDirectionDown; d <<= 1) {
		UISwipeGestureRecognizer *sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
		sgr.direction = d;
		[_overlay addGestureRecognizer:sgr];
	}

	[_overlay makeKeyAndVisible];

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
		((SB2048Icon *)v.icon).value = [obj intValue];
		if (kCFCoreFoundationVersionNumber <= 800) { // < iOS 7
			[v updateLabel];
		} else {
			[v _updateLabel];
		}
		v.frame = frameForPosition(positionForIndex(idx));
		[_board addSubview:v];
		[v release];
	}];
}

- (void)dismiss {
	if (_currentLayout) {
		[_currentLayout release];
		_currentLayout = nil;
	}
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

	[self revealIcons];

#if FILE_OUTPUT
	remove("/User/2048oard.txt");
#endif /* FILE_OUTPUT */
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
			[self show];
		});
	} else {
		_showing = NO;
		[self dismiss];

		if (_folderToOpen) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				[ic openFolder:_folderToOpen animated:YES];
				_folderToOpen = nil;
			});
		}
	}
	return _showing;
}

- (void)handleSwipeGesture:(UISwipeGestureRecognizer *)gestureRecognizer {
	UISwipeGestureRecognizerDirection dir = gestureRecognizer.direction;
#if DEBUG
	switch (dir) {
	case UISwipeGestureRecognizerDirectionRight:
		[_overlay setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:0.3]];
	break;
	case UISwipeGestureRecognizerDirectionLeft:
		[_overlay setBackgroundColor:[UIColor colorWithRed:0 green:1 blue:0 alpha:0.3]];
	break;
	case UISwipeGestureRecognizerDirectionUp:
		[_overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:1 alpha:0.3]];
	break;
	case UISwipeGestureRecognizerDirectionDown:
		[_overlay setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:0 alpha:0.3]];
	break;
	}
#endif

	BOOL b = canMakeMovements(_preview);
	if (!b) {
		// Present end screen
	}

	NSMutableArray *newValues = [processArrayWithDirection(_preview, dir) mutableCopy];
//	NSLog(@"\033[32mX_2048oard: %@\033[0m", NSArrayDescriptionInSingleLine(_preview));
	if (![newValues isEqualToArray:_preview]) {
		addRandomValueToArray(newValues);
	}
	_preview = newValues;

#if FILE_OUTPUT
	FILE *fp = fopen("/User/2048oard.txt", "w");
	for (int j = 0; j < 16; j++) {
		fprintf(fp, "%d%c", [_preview[j] intValue], (j%4==3)?'\n':' ');
	}
	fclose(fp);
#endif /* FILE_OUTPUT */

	[self updateBoard];
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
