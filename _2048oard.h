#import <UIKit/UIKit.h>
#import <libactivator/libactivator.h>

@interface _2048oard : NSObject <LAListener, UIGestureRecognizerDelegate> {
}
@property (nonatomic, retain) NSMutableArray *preview;

// UI
@property (nonatomic, assign) BOOL showing;
@property (nonatomic, retain) UIWindow *overlay;
@property (nonatomic, retain) UIWindow *board;
@property (nonatomic, retain) UIView *gameOverScreen;

@property (nonatomic, assign) id folderToOpen;

+ (id)sharedInstance;

- (void)show;
- (void)dismiss;

@end
