// EXAMPLE OF HOW TO USE INJECT
// DON'T DELETE THIS FILE FOR NOW :)

import SwiftUI
import Inject        // 1️⃣ make sure the Inject package is imported

struct TmpView: View {
  @ObserveInjection var redraw   // 2️⃣ observe injection events

  var body: some View {
    Text("🔥 Hot reload works now! YES!")
      .padding()
      .enableInjection()          // 3️⃣ tell SwiftUI to redraw on injection
  }
}
