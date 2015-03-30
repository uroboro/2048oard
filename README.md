# 2048oard
2048 right in your SpringBoard

Still a work in progress.

Instructions to play:
 - If an icon for this tweak shows up on your SpringBoard, tap it to start. Otherwise, assign an activator action to start/stop playing.
 - Swipe up, down, left, right to move icons.
 - Tap with two fingers to stop playing.
 - If you have no more moves left to do, an end screen will pop up with your maximum score made in the game and will have two buttons, one to play again and one to exit the game.

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
- Load and save games (one at a time). Also save a maximum score overall.

~~Current board is written to `/User/2048oard.txt` so keep refreshing that file after each swipe. It is also sent to the syslog in a single line description of an NSArray, just filter for "X_2048oard".~~ (No longer needed)
