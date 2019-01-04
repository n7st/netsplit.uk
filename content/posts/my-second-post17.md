---
title: "My Second Post17"
date: 2018-12-10T11:51:16Z
draft: false
type: post
tags: [ "foo", "bar" ]
authors: [ "Mike Jones", "Someone Else" ]
description: |
    This should be displayed instead. Is this now a multiline summary? I hope
    so, but let's see. Excellent.
---

**Test.**

{{< highlight perl "linenos=table,hl_lines=2 15-17,linenostart=199" >}}
sub do_the_thing {
    my $self  = shift;
    my $thing = shift;

    return $thing->do($self->do_other_thing);
}
{{< / highlight >}}

