#!/usr/bin/swift
// inspired by: https://gist.github.com/rnorth/040d0395036d8066740da321e830d666
//
// agenda: exports today's calendar entries from Mac Calendar.app into a markdown file to enable note-taking
// 
// Example usage:
//   agenda > agenda-$(date +%Y-%m-%d).md
// 


import EventKit

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

func handleDenied() {
  print("No access to calendars")
}

func handleAuthorized(store:EKEventStore, semaphore:DispatchSemaphore) {
  store.requestAccess(to: .event, completion: { (success, error) -> Void in
    let events = collectEvents(store: store)
    var eventsSet: Set = Set<String>()
    
    // printTodaysDate()
    
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
  let dateFormatter = buildDateFormatter()
  let timeFormatter = buildTimeFormatter()
  let date = dateFormatter.string(from: event.startDate)
  let start = timeFormatter.string(from: event.startDate)
  let end = timeFormatter.string(from: event.endDate)
  let title = sanitizeEventTitle(event: event)
  let eventDescription = "- `\(start) - \(end)` [[\(date) - \(title)]]"

  return eventDescription;
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
    print("default")
    break
}

semaphore.wait()
