# Delphi Image Search and Screenshot Capture with GDI+

This Delphi project provides a function that uses Windows GDI+ to capture a screenshot of a specific window or the entire screen and searches for a given PNG or BMP image within that screenshot. If the image is found, the function returns the X and Y coordinates of the match.

## Features

- Capture screenshots of a specific window or the entire screen.
- Search for a specific PNG/BMP image within the captured screenshot.
- Return the X and Y coordinates of the matched image location.
- Utilizes Windows GDI+ for image processing and screenshot capture.

## Usage

Here's a simple example of how to use the `ImageSearch` function to search for an image within the entire screen:

```delphi
var
  FoundPoint: TPoint;
begin
  // Get the handle of the entire desktop
  FoundPoint := ImageSearch('C:\path\to\subimage.png', GetDesktopWindow);
  if (FoundPoint.X <> -1) and (FoundPoint.Y <> -1) then
    ShowMessage('Image found at: ' + IntToStr(FoundPoint.X) + ', ' + IntToStr(FoundPoint.Y))
  else
    ShowMessage('Image not found.');
end;

### Parameters

- **sSubImageFile**: Path to the PNG or BMP image file to search for.
- **aWndHandle**: Handle of the window where the screenshot will be captured. Use `GetDesktopWindow` to capture the entire screen.

### Return Value

- The function returns a `TPoint` structure:
  - `X`: The X-coordinate of the top-left corner where the image was found.
  - `Y`: The Y-coordinate of the top-left corner where the image was found.
  - Returns `(-1, -1)` if the image is not found.

