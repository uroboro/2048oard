#import "SB2048Icon.h"
#import "_2048oard.h"

CGFloat fontSizeForStringWithFontConstrainedToSizeMinimumFontSize(NSString *string, UIFont *font, CGSize size, CGFloat minimumFontSize) {
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

%subclass SB2048Icon : SBIcon

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

	NSUInteger variant = 15;
	CGFloat scale = 2.0;
	NSUInteger flags = 1 << 1;
	// 1 is glossy, rounded-corners
	// 2 is !glossy, rounded-corners
	// 4 is !glossy, !rounded-corners
	void *MobileIcons = dlopen("/System/Library/PrivateFrameworks/MobileIcons.framework/MobileIcons", RTLD_NOW);
	CGImageRef (*LICreateIconForImage)(CGImageRef image, NSUInteger variant, NSUInteger flags) = NULL;
	LICreateIconForImage = (CGImageRef (*)(CGImageRef image, NSUInteger variant, NSUInteger flags))dlsym(MobileIcons, "LICreateIconForImage");
	CGImageRef themedImage = LICreateIconForImage(img.CGImage, variant, flags);
	UIImage *i = [[[UIImage alloc] initWithCGImage:themedImage scale:scale orientation:UIImageOrientationUp] autorelease];
	CGImageRelease(themedImage);
	return i;
}

%new
- (UIImage *)imageFromString:(NSString *)text {
	CGSize s = [%c(SBIconView) defaultIconImageSize];
	CGFloat fontSize = fontSizeForStringWithFontConstrainedToSizeMinimumFontSize(text, [UIFont systemFontOfSize:s.height], s, 10);
	CGPoint p = CGPointMake(0, 0);
	s.height = fontSize;
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

%new
- (UIView *)getIconView:(int)image {
	CGSize s = [%c(SBIconView) defaultIconImageSize];

	UIView *view = [[UIView alloc] initWithFrame:CGRectInset(CGRectMake(0, 0, s.width, s.height), 2, 2)];
	view.opaque = NO;
	view.backgroundColor = [self colorForValue:self.value];
//	view.layer.cornerRadius = 15;
//	view.layer.masksToBounds = YES;

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
	textLabel.center = view.center;
	[view addSubview:textLabel];
	[textLabel release];

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

- (void)launch {
	[[%c(_2048oard) sharedInstance] show];
}

- (void)launchFromViewSwitcher {
	[[%c(_2048oard) sharedInstance] show];
}

- (void)launchFromLocation:(int)location {
	[[%c(_2048oard) sharedInstance] show];
}

%end