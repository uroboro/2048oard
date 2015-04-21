#include "interfaces.h"

@interface SB2048Icon : SBLeafIcon
- (id)initWithLeafIdentifier:(NSString *)leafIdentifier;
@property (nonatomic, assign) NSInteger value;
- (UIImage *)imageFromView:(UIView *)view;
- (UIImage *)imageFromString:(NSString *)text;
- (UIView *)getIconView:(int)image;
- (UIColor *)colorForValue:(NSInteger)value;
@end
