# 7. Module 6 — NPV / NPIV (5.1.b)

**Objective:** understand and verify the NPV/NPIV relationship that lets many blade WWPNs share a small number of physical FI uplinks.

## 7.1 Concept Recap

- **NPIV** (N-Port ID Virtualization) lets a single physical N-Port register multiple FCIDs — this is what allows every blade vHBA behind an FI uplink to get its own fabric identity over one physical link.
- **NPV** (N-Port Virtualization) is the *switch-level* feature: a device (here, the FI in End Host Mode) acts as an NPV edge, aggregating downstream N-Port logins and passing them upstream via NPIV — without participating in FSPF or owning a domain ID itself.
- The **core switch** (N5K-3/N5K-4) must have `feature npiv` enabled to *accept* multiple FLOGIs/FDISCs over a single F port; this pod ships with it already enabled, which you confirmed back in Section 1.1 rather than configuring it yourself.

## 7.2 Task 6.1 — Confirm NPIV on the Core

`show npv status` is a real command, but it reports whether *this device* is acting as an NPV edge — it's what you run on the FI (Task 6.2), not on the core switch. On N5K-3/N5K-4 (which just has the NPIV *feature* enabled, not NPV mode), confirm the feature is on and prove it's working by checking that the fabric actually accepted multiple FCIDs over a single F port:

??? "Commands"
    ```text
    show feature | include npiv
    show flogi database vsan 100
    ```

Multiple pWWN entries all logged in via the *same* physical interface is the real proof NPIV is functioning — a feature flag being "enabled" doesn't by itself confirm anything actually used it yet.

## 7.3 Task 6.2 — Observe NPV Behavior on the FI

The FI itself, in End Host Mode, is functioning as the NPV device. From the FI's NX-OS-like CLI:

??? "Commands"
    ```text
    show npv flogi-table
    show npv internal info
    ```

You should see one row per downstream vHBA, all funneling through the same uplink FCID.

## 7.4 Task 6.3 — Verify at the Core

??? "Commands"
    ```text
    show flogi database vsan 100
    show fcns database vsan 100
    ```

Confirm multiple pWWNs (one per blade vHBA) all logged in via the *same* interface (the FI uplink) — this is NPIV in action, and it's the single clearest piece of exam-relevant evidence you can screenshot for your own notes.

!!! question "Check yourself"
    What would `show flogi database` look like differently if the FI were in Switch Mode instead of End Host Mode?
