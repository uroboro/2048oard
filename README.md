# 2048oard
2048 right in your SpringBoard

Still a work in progress.

To do:
- ~~Add random initialization.~~
- ~~Add random (1 or 2 depending on the amount of empty slots) value (2 (75%) or 4 (25%)) in an empty slot after each swipe.~~
- ~~Properly display board with SBIconViews.~~
- ~~Implement custom SBIconViews to display values in a more convenient manner than the icon badge. This also removes dependence on manipulating SBIcons~~
- Balance randomness of initilization and new values insertion.
- Replicate normal SBIconViews with SB2048IconViews in terms of size, shape, gloss (if needed), font.
- ~~Make SB2048IconViews update when their SB2048Icon is modified (its `value`)~~
- Keep track of SB2048IconViews to allow animating their movement on swipes.
- ~~Don't add new values if no moves were done.~~

~~Current board is written to `/User/2048oard.txt` so keep refreshing that file after each swipe. It is also sent to the syslog in a single line description of an NSArray, just filter for "X_2048oard".~~ (No longer needed)
