#import "@preview/fontawesome:0.6.0": *
#import "@preview/linguify:0.4.2": *
#import "lib.typ": *
// #import "@preview/modern-cv:0.9.0": *


#let priority-threshold = state("priority-threshold", int(0))

#let show-tags = state("show-tags", none)

#let set-priority-threshold(priority) = {
  priority-threshold.update(int(priority))
}

#let reduce-threshold() = {
  priority-threshold.update(old => old - 1)
}

#let get-priority-threshold() = {
  return int(priority-threshold.get())
}

#let set-show-tags(tags) = {
  show-tags.update(tags)
}

#let color-darkgray = rgb("#333333")

#let git-link(url, alt, icon: fa-icon("gitlab")) = [#link(url, [#icon #alt])]

#let justified-header(primary, secondary) = {
  set block(above: 0.7em, below: 0.5em)
  pad[
    #__justify_align(box[
      == #primary
    ])[
      #secondary-right-header[#secondary]
    ]
  ]
}

#let resume-entry(
  title: none,
  location: "",
  date: "",
  description: "",
  title-link: none,
  accent-color: default-accent-color,
  location-color: default-location-color,
  priority: 0,
  // threshold: 0,
  tags: (),
  ..args,
) = context {
  let threshold = priority-threshold.get()

  if priority > threshold {
    return
  }
  // [#(threshold, priority)]

  let stags = show-tags.get()

  if stags != none {
    let included = false
    for tag in tags {
      if tag in stags {
        included = true
        break
      }
    }
    if included == false {
      return
    }
  }

  // entry-list.update(old => (
  //   old,
  // {
  let title-content
  if type(title-link) != type(none) {
    title-content = link(title-link)[#title]
  } else {
    title-content = title
  }
  block(above: 1em, below: 1em)[
    #pad[
      #justified-header(title-content, date)
      #if description != "" or location != "" [
        #secondary-justified-header(description, location)
      ]
    ]
  ]
  if args.pos().join() != none {
    [#resume-item(args.pos().join())]
  }
  //   },
  // ))
}

#let render-adjusted-entries(body) = block(height: 1fr, layout(size => {
  let max-threshold = 10
  for i in range(max-threshold, 0, step: -1) {
    let measured-height = measure(body(i), width: size.width)
    // [#i #measured-height.height #size.height]
    if measured-height.height < size.height {
      body(i)
      return
    }
  }
  body(0)
}))


#let is-heading(it) = {
  it.func() == heading
}

#let wrapp-section(
  body,
  threshold: 0,
  wrapper: none,
) = {
  // The heading of the current section
  let heading = none
  // The content of the current section
  let section = ()

  for it in body.children {
    let x = it.func()

    if is-heading(it) {
      if heading != none {
        // Complete the last section
        heading
        if section != () {
          [#section.join()]
        }
        heading = none
        section = ()
      }
      heading = it
    } else if heading != none {
      // Continue the current section
      if it.func() == resume-entry {}
      [#it.func() ]
      section.push(it)
    } else {
      it // if not in any section (before the first heading of the appropriate depth)
    }
  }

  // Complete the last section
  if heading != none {
    wrapper(heading: heading, section: section.join())
  }
}

#let fill-box-with-text(min: 0.3em, max: 5em, eps: 0.1em, it) = layout(
  size => {
    let fits(text-size, it) = {
      let text-size = measure({
        set text(text-size)
        it
      })
      text-size.height <= size.height and text-size.width <= size.width
    }

    if not fits(min, it) {
      panic("Content doesn't fit even at minimum text size")
    }
    if fits(max, it) {
      set text(max)
      it
    }

    let (a, b) = (min, max)
    while b - a > eps {
      let new = 0.5 * (a + b)
      if fits(new, it) {
        a = new
      } else {
        b = new
      }
    }

    set text(a)
    it
  },
)
