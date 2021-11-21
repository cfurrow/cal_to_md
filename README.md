# cal_to_md.swift
Swift script to fetch today's events, and output them to a markdown list with Obsidian-style links to notes `[[]]`. 

My primary use case is to output this list once a day and put them in my markdown notes, so if I want to keep individual meeting or appointment notes, I can use Obsidian to easily create the note tied to an event.

## Usage

```shell
./cal_to_md.swift

- `12:00 AM - 12:00 AM` [[2021-11-21 - Amy Frank's 30th Birthday]]
- `08:00 AM - 09:15 AM` [[2021-11-21 - Finance call]]
- `12:00 PM - 01:00 AM` [[2021-11-21 - Lunch]]
- `02:15 PM - 02:45 PM` [[2021-11-21 - Team Sync]]
- `03:00 PM - 03:30 PM` [[2021-11-21 - 1-1 with Jeff]]
```

