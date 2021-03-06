# cal_to_md.swift
Swift script to fetch today's events, and output them to a markdown list with Obsidian-style links to notes `[[]]`. 

My primary use case is to output this list once a day and put them in my markdown notes, so if I want to keep individual meeting or appointment notes, I can use Obsidian to easily create the note tied to an event.

## Usage

```shell
# Output default
./cal_to_md.swift
# Output with event names surrounded in wiki-link brackets
WIKI_LINK=true ./cal_to_md.swift
# Output with a mermaidjs gantt chart above the list of events
GANTT_CHART=true ./cal_to_md.swift
# Output the gantt chart, as well as use wiki-links to surround events in the list
WIKI_LINK=true GANTT_CHART=true ./cal_to_md.swift
```

Example Output:
```markdown
- `12:00 AM - 12:00 AM` [[2021-11-21 - Amy Frank's 30th Birthday]]
- `08:00 AM - 09:15 AM` [[2021-11-21 - Finance call]]
- `12:00 PM - 01:00 AM` [[2021-11-21 - Lunch]]
- `02:15 PM - 02:45 PM` [[2021-11-21 - Team Sync]]
- `03:00 PM - 03:30 PM` [[2021-11-21 - 1-1 with Jeff]]
```



## Alfred Workflow Configuration
WIKI_LINK [true|false] - Surround event names in wikilink-style [[ and ]]
GANTT_CHART [true|false] - Turn the gannt chart on or off

## TODO
- How to make asking for permissions easier for new users.

## Thanks to [rnorth](https://gist.github.com/rnorth)
This script was inspired by their gist: https://gist.github.com/rnorth/040d0395036d8066740da321e830d666

calendar.png from [commons.wikimedia.org](https://commons.wikimedia.org/wiki/File:Calendar_vmc2015.png)

# Contribute
1. Fork the repository
2. Create a new branch
3. Make your changes
4. Commit all your changes to your branch
5. Create a Pull Request against this repo
  1. Be sure to explain the changes you've made, and why you've made them.
  2. You can tag me in the PR description

# Changes

## v1.5.0
Added GANTT_CHART option to script, and alfred workflow. Can turn the gantt chart on/off.
## v1.4.1
Fix bugs #10 and #11

## v1.4.0
Add gantt chart
## v1.3.0
Add alfred build script

## v1.2.1
Output a message when no events found for the current day.

## v1.2.0
Added WIKI_LINK environment variable

## v1.1.0
Created alfred workflow

