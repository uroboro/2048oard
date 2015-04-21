#include "interfaces.h"

@interface SB2048Icon : SBIcon
@property (nonatomic, assign) NSInteger value;
- (UIImage *)imageFromView:(UIView *)view;
- (UIImage *)imageFromString:(NSString *)text;
- (UIView *)getIconView:(int)image;
- (UIColor *)colorForValue:(NSInteger)value;
@end
