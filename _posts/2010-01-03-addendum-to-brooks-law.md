---
title: Addendum to Brook's Law
date: 2010-01-03
author: Brent McConnell
layout: post
permalink: /2010/01/addendum-to-brooks-law/
the_sub_subtitle:
  - Impact of Management Overhead
categories:
  - Getting Things Done
tags: productivity
summary: |
 Are all communication nodes equal in Brook's theory or intercommunication on a project?
excerpt_separator: <!--more-->
---
I just read Joel Spolsky’s blog entitled [A Little Less Conversation](http://www.inc.com/magazine/20100201/a-little-less-conversation.html) which discusses __communication overload__.  After reading that post I began to consider my own personal experience in meetings over the last dozen or so years and decided to add an addendum to the communication node problem that was so eloquently detailed in the Mythical Man Month by Brooks.
<!--more-->
The problem with Brooks’ theory of intercommunication is that it doesn’t take into account the “Number of Managers” in any given meeting.  He assumes in his <a href="http://en.wikipedia.org/wiki/The_Mythical_Man-Month" target="_blank">calculation</a> that all nodes in a communication network are equal.  This is a mistake.  All nodes are not equal, as anyone who has sat through a meeting with more than one manager participating can attest to.

Managers have keen insight into every major (and minor) issue at hand and willingly share that information with the team in a seemingly endless discourse that greatly adds to the meeting’s productivity and value.  In fact I’ve been in meetings with multiple managers that have lasted two, maybe three, times longer than the scheduled meeting length due to the significant wisdom that each of the managers was imparting to their counterparts and the team.

This imbalance in communication node weighting should be reflected in a revised formula for group intercommunication (especially meetings).  Brooks’ original formula can be stated as <em>n(n-1)/2=communication pathways. </em>The revised formula adds the significance of management communication to the pathways problem by accurately describing the impact of management on the original formula.  This new formula can be expressed as (<em>n(n-1/2)) ^x </em>(^x indicates raised to the power of x) where <em>x</em> is the number of managers.

As an example I will restate the original example given by Brooks and then show the difference when true communication weighting has been added…

Example: 50 developers give 50 · (50 – 1) / 2 = 1225 channels of communication.

However, given our new formula and assuming the presence of 3 managers (or significant stakeholders) into our team we now see the impact of the additional management on our communication overhead.

Example: 50 developers + 3 Managers give (50 · (50 – 1) / 2)^3  = 1838265625 channels of communication.

There, that’s better.  This new formula clearly shows the benefit of adding additional management resources to any project.
