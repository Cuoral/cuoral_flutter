## 0.0.1

* First release of cuoral flutter SDK


## 0.0.2

* Allow 3.7.0 flutter version


## 0.0.3

* added optional email, first name and last name parameters


## 0.0.4

* fix file input issue


## 0.0.5

* Full customer intelligence tracking (page views, console errors, network errors, custom events)
* Automatic event batching and queueing
* Native crash tracking (Android & iOS) with deduplication
* Screen recording support (Android MediaProjection, iOS ReplayKit)
* Automatic HTTP interception for network error tracking
* Session persistence with 30-day expiry
* Navigation observer with dialog/popup filtering
* Profile setting integration


## 0.0.6

* Auto-detect page widget names for MaterialPageRoute without named routes
* Improved navigation tracking for unnamed route patterns


## 0.0.7

* Fix page name detection timing for unnamed MaterialPageRoute
* Defer widget tree inspection to post-frame callback for reliability


## 0.0.8

* Fix page name detection for unnamed MaterialPageRoute (was showing /page)
* Expanded framework widget skip list for more reliable page name extraction
* Added retry mechanism for widget tree inspection during route animations
* Added route.toString() parsing as fallback strategy


## 0.0.9

* Added CuoralLauncher.open() static method for programmatic widget opening
* Graceful 502/504 degradation
