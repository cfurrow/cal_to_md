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

// TODO: how can we give a more helpful message here? What can a user do to fix this?
func handleDenied() {
  print("No access to calendars")
}

func handleAuthorized(store:EKEventStore, semaphore:DispatchSemaphore) {
  store.requestAccess(to: .event, completion: { (success, error) -> Void in
    let events = collectEvents(store: store)
    var eventsSet: Set = Set<String>()
    
    // printTodaysDate()
    
    if events.count == 0 {
      print("No events today")
    } 

    for event in events {
      if (event.status == EKEventStatus.canceled) {
        continue
      }
      
      let eventDescription = buildEventDescription(event: event)
      
      // Do not print duplicates
      if ( !eventsSet.contains(eventDescription) ) {
        eventsSet.insert(eventDescription)
        print(eventDescription)
      }
    }
    
    semaphore.signal()
  })
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

func printTodaysDate() {
  let date = Date()
  let dateFormatter = buildDateFormatter()
  print(dateFormatter.string(from: date))
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

  return "- `\(start) - \(end)` \(eventName)"
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
