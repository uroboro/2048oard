#import "SB2048Icon.h"
#import "_2048oardController.h"

typedef enum LIIconMask {
	LIIconMaskRoundedGlossy = 1 << 0,
	LIIconMaskRounded = 1 << 1,
	LIIconMaskNone = 1 << 2
} LIIconMask

static UIColor *colorForValue(NSInteger value) {
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

static UIImage *imageFromView(UIView *view) {
	UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
	[view.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return img;
}

static UIImage *iconImageFromImage(UIImage *image, CGFloat scale, NSUInteger variant, NSUInteger mask) {
	static void *MobileIcons = NULL;
	static CGImageRef (*LICreateIconForImage)(CGImageRef image, NSUInteger variant, NSUInteger mask) = NULL;
	if (!MobileIcons) {
		MobileIcons = dlopen("/System/Library/PrivateFrameworks/MobileIcons.framework/MobileIcons", RTLD_NOW);
	}
	if (!LICreateIconForImage) {
		LICreateIconForImage = (CGImageRef (*)(CGImageRef image, NSUInteger variant, NSUInteger mask))dlsym(MobileIcons, "LICreateIconForImage");
	}
	CGImageRef themedImage = LICreateIconForImage(image.CGImage, variant, mask);
	UIImage *i = [[[UIImage alloc] initWithCGImage:themedImage scale:scale orientation:UIImageOrientationUp] autorelease];
	CGImageRelease(themedImage);
	return i;
}

static UIImage *iconImageFromView(UIView *view) {
	UIImage *img = imageFromView(view);

	CGFloat scale = 2.0;
	NSUInteger variant = 15; // http://iphonedevwiki.net/index.php/MobileIcons.framework#Variants
	LIIconMask mask = LIIconMaskRounded;
	// flags = (kCFCoreFoundationVersionNumber > 800.0) would mean that gloss is applied to icons on iOS 6 or earlier
	// if the animations aren't changed, this becomes a bit laggy in this project
	return iconImageFromImage(img, scale, variant, mask);
}

static CGFloat fontSizeForStringWithFontConstrainedToSizeMinimumFontSize(NSString *string, UIFont *font, CGSize size, CGFloat minimumFontSize) {
	int m = NSLineBreakByWordWrapping; //UILineBreakModeWordWrap
	CGFloat fontSize = [font pointSize];
	CGFloat height = [string sizeWithFont:font constrainedToSize:CGSizeMake(size.width,FLT_MAX) lineBreakMode:m].height;
	UIFont *newFont = font;

	//Reduce font size while too large, break if no height (empty string)
	while (height > size.height && height != 0 && fontSize > minimumFontSize) {
		fontSize--;
		newFont = [UIFont fontWithName:font.fontName size:fontSize];
		height = [string sizeWithFont:newFont constrainedToSize:CGSizeMake(size.width, FLT_MAX) lineBreakMode:m].height;
	};

	// Loop through words in string and resize to fit
	for (NSString *word in [string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]) {
		CGFloat width = [word sizeWithFont:newFont].width;
		while (width > size.width && width != 0 && fontSize > minimumFontSize) {
			fontSize--;
			newFont = [UIFont fontWithName:font.fontName size:fontSize];
			width = [word sizeWithFont:newFont].width;
		}
	}
	return fontSize;
}

static UIImage *imageFromString(NSString *text) {
	CGSize s = [%c(SBIconView) defaultIconImageSize];
	s = CGRectInset(s, 5, 5);
	CGFloat fontSize = fontSizeForStringWithFontConstrainedToSizeMinimumFontSize(text, [UIFont systemFontOfSize:s.height], s, 10);
	s.height = fontSize;
	CGPoint p = CGPointMake(0, 0);
	UIGraphicsBeginImageContextWithOptions(s, 0, 0.0);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, [[UIColor lightGrayColor] CGColor]);
	CGContextSetStrokeColorWithColor(context, [[UIColor darkGrayColor] CGColor]);
	CGContextSetTextDrawingMode(context, kCGTextFillStroke);
	[text drawAtPoint:p withFont:[UIFont systemFontOfSize:fontSize]];
	UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return img;
}

%subclass SB2048Icon : SBLeafIcon

%group iOS_LT5

%new
- (id)initWithLeafIdentifier:(NSString *)leafIdentifier {
	if ((self = [self init])) {
		objc_setAssociatedObject(self, @selector(leafIdentifier), leafIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
	}
	return self;
}

%new
- (NSString *)leafIdentifier {
	return objc_getAssociatedObject(self, @selector(leafIdentifier));
}

%end

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
- (UIView *)getIconView:(int)image {
	CGSize s = [%c(SBIconView) defaultIconImageSize];

	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, s.width, s.height)];
	view.opaque = NO;
	view.backgroundColor = colorForValue(self.value);

/*	UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectInset(view.frame, 5, 5)];
	valueLabel.backgroundColor = [UIColor clearColor];
	valueLabel.textColor = [UIColor lightGrayColor];
	valueLabel.text = [NSString stringWithFormat:@"%d", self.value];
	valueLabel.font = [UIFont systemFontOfSize:valueLabel.frame.size.height];
	valueLabel.adjustsFontSizeToFitWidth = YES;
	valueLabel.textAlignment = NSTextAlignmentCenter;
	valueLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	[view addSubview:valueLabel];
	[valueLabel release];
*/
	UIImage *img = [self imageFromString:[NSString stringWithFormat:@"%d", self.value]];
	UIImageView *textLabel = [[UIImageView alloc] initWithImage:img];
//	textLabel.center = view.center;
	[view addSubview:textLabel];
	[textLabel release];

	return [view autorelease];
}

- (UIImage *)getIconImage:(int)image {
	return iconImageFromView([self getIconView:image]);
}

- (UIImage *)getGenericIconImage:(int)image {
	return iconImageFromView([self getIconView:image]);
}

- (UIImage *)generateIconImage:(int)image {
	return iconImageFromView([self getIconView:image]);
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
	return [NSString stringWithFormat:@"2048-%d", self.value];
}

- (BOOL)launchEnabled {
	return YES;
}

- (void)launch {
//	[[%c(_2048oard) sharedInstance] show];
}

- (void)launchFromViewSwitcher {
//	[[%c(_2048oard) sharedInstance] show];
}

- (void)launchFromLocation:(int)location {
//	[[%c(_2048oard) sharedInstance] show];
}

%end

%ctor {
	%init();
	if (kCFCoreFoundationVersionNumber < 700.0) {
		%init(iOS_LT5);
	}
}
