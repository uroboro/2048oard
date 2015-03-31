#ifndef INTERFACES_H
#define INTERFACES_H

#import <UIKit/UIKit.h>

@interface SBIconListView : UIView
- (NSArray *)icons;
@end

@interface SBIcon : NSObject
- (NSString *)applicationBundleID;
- (NSInteger)badgeValue;
- (id)badgeNumberOrString;
- (void)setBadge:(id)arg1;
- (NSString *)displayName;
- (id)getIconImage:(NSInteger)arg1;
- (void)reloadIconImagePurgingImageCache:(BOOL)arg1;
- (void)launchFromViewSwitcher;
@end

@interface SBIconController : NSObject
+ (id)sharedInstance;
- (id)model;
- (id)openFolder;
- (BOOL)hasOpenFolder;
- (BOOL)hasAnimatingFolder;
- (void)closeFolderAnimated:(BOOL)animated;
- (void)openFolder:(id)arg1 animated:(BOOL)animated;
- (SBIconListView *)currentRootIconList;
- (void)addNewIconToDesignatedLocation:(SBIcon *)icon animate:(BOOL)animate scrollToList:(BOOL)scrollToList saveIconState:(BOOL)saveIconState;
@end

@interface SBIconViewMap : NSObject
+ (id)homescreenMap;
- (id)mappedIconViewForIcon:(id)arg1;
@end

@interface SBIconModel : NSObject
@property (nonatomic, assign) id delegate;
- (void)loadAllIcons;
- (void)addIcon:(SBIcon *)icon;
@end

@interface SBIconView : UIView
@property (nonatomic, assign) SBIcon *icon;
+ (CGSize)defaultIconSize;
+ (CGSize)defaultIconImageSize;
- (id)initWithDefaultSize;
- (void)updateLabel; // < iOS 7
- (void)_updateLabel; // >= iOS 7
@end

#endif /* INTERFACES_H */