## 0.1.6

* **CRITICAL FIX:** `CuoralNavigationObserver` now uses the enhanced unnamed-route detector (`CuoralNavigatorObserver`) internally
* Fixed production issue where apps using `CuoralNavigationObserver()` still resolved unnamed `MaterialPageRoute` screens as `/page`
* Removed temporary debug logging from navigator detection internals


## 0.1.5

* **CRITICAL FIX:** Reordered route detection strategies to parse route.toString() FIRST before widget tree walking
* Added better regex patterns to detect screen names from MaterialPageRoute builder lambda syntax (=> WidgetName)
* Fixed issue where route.subtreeContext was null/unavailable causing all unnamed routes to show as "/page"
* Now detects unnamed routes like `Navigator.push(context, MaterialPageRoute(builder: (context) => ScreenName()))` correctly


## 0.1.4

* Enhanced unnamed route detection with deep widget tree traversal (up to 20 levels)
* Smart prioritization of user-defined widgets over framework widgets
* Expanded framework widget filtering (80+ Flutter widgets)
* Improved detection for wrapped, nested, and generic widget class names
* Better handling of MaterialPageRoute without RouteSettings names


## 0.1.3

* Fixed WebView scroll issues by adding gesture recognizers for vertical and horizontal drag
* Improved touch and scroll responsiveness within the chat widget


## 0.1.2

* Fixed close button icon color to always be visible (black87) against white background
* Added automatic SSL certificate handling for Cuoral domains to prevent hanging/delays
* Added WebView caching with LOAD_DEFAULT mode (respects server cache-control headers)
* Enabled third-party cookies and shared cookies for better API communication
* Performance optimizations while allowing quick updates via server cache headers


## 0.1.1

* Fixed close button icon color to always be visible (black87) against white background
* Added automatic SSL certificate handling for Cuoral domains to prevent hanging/delays
* Added WebView caching with LOAD_DEFAULT mode (respects server cache-control headers)
* Enabled third-party cookies and shared cookies for better API communication
* Performance optimizations while allowing quick updates via server cache headers


## 0.1.1

* Fixed overlay positioning to use rootOverlay, preventing host app's bottom nav from blocking chat tabs
* Chat overlay now properly covers entire screen including host app navigation bars


## 0.1.0

* Persistent WebView overlay for instant re-opens without reload
* Smooth slide-up/slide-down animations (300ms)
* Fixed navigation errors when closing chat widget
* Disabled WebView zoom on keyboard input
* Improved floating close button design (smaller, circular)
* CuoralOverlay singleton pattern for memory efficiency


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
