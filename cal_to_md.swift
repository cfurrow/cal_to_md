#!/usr/bin/swift
// inspired by: https://gist.github.com/rnorth/040d0395036d8066740da321e830d666
//
// cal_to_md.swift: exports today's calendar entries from Mac Calendar.app into a markdown file to enable note-taking
// 
// Example usage:
//   ./cal_to_md.swift > agenda-$(date +%Y-%m-%d).md
// 

import EventKit
import Foundation

let semaphore = DispatchSemaphore(value: 1)

defer {
  semaphore.wait()
}

let store = EKEventStore()

class BaseFormatter {
  var events: [EKEvent] = []
  var output : String

  init(events: [EKEvent]) {
    self.events = events
    self.output = ""
  }

  func buildDateFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter;
  }

  func buildTimeFormatter() -> DateFormatter {
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "hh:mm aa"
    return timeFormatter;
  }

  func todaysDate() -> String {
    let date = Date()
    let dateFormatter = buildDateFormatter()
    return dateFormatter.string(from: date);
  }

  // Remove some common characters from the event description to allow for file creation.
  // For example, if an event title is "1:1 Carl<>Frank" the sanitizer will remove ':', '<' and '>'
  // and the output will be "11 CarlFrank", and this is a valid filename that can be created
  // for the event in an app like Obsidian, etc.
  func sanitizeEventTitle(event:EKEvent) -> String {
    return event.title!
        .replacingOccurrences(of: "FW: ", with: "")
        .replacingOccurrences(of: ":", with: "")
        .replacingOccurrences(of: "&", with: "and")
        .replacingOccurrences(of: "<", with: "")
        .replacingOccurrences(of: ">", with: "")
        .replacingOccurrences(of: "*", with: "")
        .replacingOccurrences(of: "/", with: "-")
  }

  func buildEventDescription(event:EKEvent) -> String {
    let surroundEventNameWithWikiLink = ProcessInfo.processInfo.environment["WIKI_LINK"]

    let dateFormatter = buildDateFormatter()
    let timeFormatter = buildTimeFormatter()
    let date = dateFormatter.string(from: event.startDate)
    let start = timeFormatter.string(from: event.startDate)
    let end = timeFormatter.string(from: event.endDate)
    let title = sanitizeEventTitle(event: event)
    
    var eventName = "\(date) - \(title)"
    if(surroundEventNameWithWikiLink?.lowercased() == "true") {
      eventName = "[[\(eventName)]]"
    }

    return "`\(start) - \(end)` \(eventName)"
  }

  func format(event: EKEvent) -> String {
    return "i do nothing"
  }

  func header() -> String {
    return ""
  }

  func footer() -> String {
    return ""
  }

  func build() -> String {
    self.output.append(self.header());
    for event in self.events {
      if (event.status == EKEventStatus.canceled) {
        continue
      }
      self.output.append(format(event: event))
    }
    self.output.append(self.footer());
    return self.output;
  }
}

class ListFormatter : BaseFormatter {
  override func format(event: EKEvent) -> String {
    let eventDescription = buildEventDescription(event: event)
      
    return "- \(eventDescription)\n"
  }
}

class GanttFormatter : BaseFormatter {
  override func header() -> String {
    return """
    ```mermaid
    gantt
    dateFormat  hh:mm A
    axisFormat %I:%M%p
    title Today's Agenda\n\n
    """
  }
  override func footer() -> String {
    return "\n```"
  }

  override func format(event: EKEvent) -> String {
    if( event.isAllDay ) {
      return "";
    }
    let eventTitle = sanitizeEventTitle(event: event)
    let timeFormatter = buildTimeFormatter()

    let start = timeFormatter.string(from: event.startDate)
    let end = timeFormatter.string(from: event.endDate)
    let eventId = "" // event.eventIdentifier
    
    return """
    \(eventTitle) : \(eventId) \(start),\(end)  \n
    """
  }
}

// TODO: how can we give a more helpful message here? What can a user do to fix this?
func handleDenied() {
  print("No access to calendars")
}

func handleAuthorized(store:EKEventStore, semaphore:DispatchSemaphore) {
  store.requestAccess(to: .event, completion: { (success, error) -> Void in
    var eventsSet: Set = Set<EKEvent>()
    let events = collectEvents(store: store)
    // Do not print duplicates
    for event in events {
      if !eventsSet.contains(event) {
        eventsSet.insert(event)
      }
    }

    // printTodaysDate()
    
    if eventsSet.count == 0 {
      print("No events today")
    } else {
      let formatter = GanttFormatter(events: Array(eventsSet))
      print(formatter.build())
    }

    semaphore.signal()
  })
}

// Fetch all of today's events, return as an array of events.
// TODO: we could attempt to de-duplicate at this point.
func collectEvents(store:EKEventStore) -> [EKEvent] {
  var calendar = Calendar.current
  calendar.timeZone = NSTimeZone.local
  
  let dateAtMidnight = calendar.startOfDay(for: Date())
  var components = DateComponents()
  components.day = 1
  components.second = -1
  let endDate = calendar.date(byAdding: components, to: dateAtMidnight)
  
  let predicate = store.predicateForEvents(withStart: dateAtMidnight, end: endDate!, calendars: nil)
  
  return store.events(matching: predicate)
}

switch EKEventStore.authorizationStatus(for: .event) {
  case .authorized:
    handleAuthorized(store: store, semaphore: semaphore)
    break
  case .denied:
    handleDenied()
    break
  case .notDetermined:
    store.requestAccess(to: .event, completion: { (granted, error) in
      if granted {
        handleAuthorized(store: store, semaphore: semaphore)
      } else {
        handleDenied()
      }
    })
    break
  default:
    print("Unknown state. Could not retrieve calendar information")
    break
}

semaphore.wait()
