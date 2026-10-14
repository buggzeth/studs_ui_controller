 HOW TO USE THIS UI PACKAGE
 

 1. FILE PLACEMENT:
    • Modal Windows (CanvasGroups):
        Place each ScreenGui (ShopGui, LuckyWheelGui, TimeRewardsGui, CodesGui, etc.)
        directly inside 'StarterGui'.
    • UI Controller (This LocalScript):
        Place this script directly inside 'StarterPlayer' > 'StarterPlayerScripts'.

 2. HOW HUD BUTTONS OPEN MODAL WINDOWS:
    • Automatic Keyword Detection:
        Any button in your HUD (Side menu, Bottom bar) automatically opens its
        corresponding window if its name contains any of these keywords:
          - "shop"    -> Opens 'ShopGui' (ShopWindow)
          - "wheel"   -> Opens 'LuckyWheelGui' (LuckyWheelWindow)
          - "spin"    -> Opens 'LuckyWheelGui' (LuckyWheelWindow)
          - "time"    -> Opens 'TimeRewardsGui' (TimeRewardsWindow)
          - "daily"   -> Opens 'DailyRewardsGui' (DailyRewardsWindow)
          - "codes"   -> Opens 'CodesGui' (CodesWindow)
          - "setting" -> Opens 'SettingsGui' (SettingsWindow)
    • Custom Target Attribute:
        You can also add a String Attribute named "TargetGui" to any GuiButton
        with the exact name of the ScreenGui (e.g., TargetGui = "ShopGui").

 3. CLOSE BUTTONS:
    • Any button named "CloseButton" inside any window automatically hooks up
      to close that specific window with a smooth pop animation.

 4. BUTTON ANIMATIONS & ANCHOR POINTS:
    • All buttons automatically receive center-anchored click bounce/squish effects.
    • Ensure any new buttons you design have AnchorPoint set to (0.5, 0.5)
      so they scale inward from their visual center on click.

 5. RESPONSIVE SCALING (MOBILE, TABLET & PC):
    • Every window CanvasGroup contains a UIScale object named "WindowScale".
    • The controller automatically measures the device viewport and adjusts
      the WindowScale dynamically, preventing UI elements from cutting off
      on smaller phone screens.

 6. SPIN WHEEL HOOKUP & REWARD DISPATCH:
    • Clicking 'SpinButton' or any multiplier button ('Mult2xBtn', etc.) triggers
      the smooth tween rotation logic.
    • To award items to the player on the server, connect a RemoteEvent inside
      the spin completion callback (e.g., GameEvents.AwardSpinPrize:FireServer(sliceIndex)).

 
