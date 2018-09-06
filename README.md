Contact Updater
===============

This application crawles all the data from your assigned groups in your main backoffice page, and adds every group as labeled contacts in your Gmail account. This way, you can write emails directly to that list.


*Requirements:
    - Having installed `pup`: https://github.com/ericchiang/pup
    - A cookie file, which you can extract from your browser, named `cookies.txt`, with the session logged in to the backoffice.


*How to make it work:

    1. Create a `cookies.txt` with the backoffice session logged, and place it into this folder. You can use the `cookies.txt` extension for chrome: https://chrome.google.com/webstore/detail/cookiestxt/njabckikapfpffapmjgojcnbfjonfjfg?hl=en

    2. run `./app.sh`, and follow the instructions

    3. You will get a filter to add in Gmail. You have to change all "before: yyyy/mm/dd" and "after: yyyy/mm/dd" in that filter to define where your quarter begins and ends. This way, Gmail will only tag the emails between those dates.
