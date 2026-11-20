# Report checklist

Run these before handing the report over. Each one has caught a real defect.

## Structure

- The verdict in the banner matches the counts in the legend
- Every step in the manifest is in the report, in the same order
- Every screenshot in the manifest is in the report
- No relative image paths remain: `grep -c "screenshots/" path/to/report.html` prints `0`
- No font folder reference remains: `grep -c "fonts/" path/to/report.html` prints `0`
- The report opens from a `file://` URL with the images visible
- The file can be moved or copied alone and still render from `file://`
- The step index at the top of the steps section lists every step and jumps to it
- The "Needs a decision" block lists every finding and jumps to it
- The nav links reach the sections they name

## Full screen image

Open one, then check:

- The image covers the whole viewport, no white band and no empty side band
- The aspect ratio of the image matches the file, no stretching
- The top bar names the shot, not only the file name
- The position counter reads "3 / 38" or whatever it should
- The previous and next buttons work, the first has no previous and the last has no next
- Esc closes it and the focus returns to the thumbnail it came from
- The arrow keys move between images
- Tab stays inside the image and cycles back to the first button
- Clicking the scrim closes it
- The report's own nav does not bleed through the scrim

## Narrow screen

At 320px wide:

- The top bar fits, the close button does not slide off screen
- A long file name is truncated rather than pushing the buttons away
- The image is readable, it is not shrunk so far that the text in it cannot be read
- The lists are one column

## Print

Print to PDF and check:

- The page count is what you expect
- The images fit on the page and are not cut in half
- The nav has wrapped rather than been cut off at the paper edge
- The full screen overlay does not appear on paper

## Prose

- English throughout
- No emoji, no em dashes, no curly quotes
- The headline says the result, not the topic
- Every failure names the exact thing that failed
- A failure that quotes the spec quotes it exactly

## Colour

- Red appears only where a result failed
- Green appears only where a result passed
- Amber appears only on a finding that needs a decision
- The frame of the report is the deep blue, not the product brand red
