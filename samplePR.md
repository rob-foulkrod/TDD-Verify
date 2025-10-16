
# Add `SecurityControl: 'Ignore'` Tag to Trainer Demo Deploy Resources for MTT Managed Subscriptions

**Short answer:** We’re adding the `SecurityControl: 'Ignore'` tag to Trainer Demo Deploy projects so resources can run in **MTT managed subscriptions** without being blocked by default security policies.

---

## What Changed
We add the following tag during deployment:

```bicep
SecurityControl: 'Ignore' // Required for MTTs in managed subscriptions
````

> This tag is applied where resource tags are assembled and propagates to all resources created by the deployment.

***

## Why This Is Needed

*   **MTT managed subscriptions** enforce strict Azure Policy/Guardrails. Demo resources (short-lived, non-prod) can be flagged or blocked by controls intended for production workloads.
*   Adding `SecurityControl: 'Ignore'` allows training/demo resources to **bypass or quiet specific automated controls** designed for production, ensuring workshops and demos proceed without policy denials.
* Elements such as authenticating to storage accounts with keys is prohibited.

***

## Scope

*   Applies to all Trainer Demo Deploy repos using the shared tagging pattern.
*   Only affects **tags**; no changes to resource SKUs, regions, or identities.
*   Intended specifically for **training/demo** resources in **managed MTT subscriptions**.

***

## How It Works

*   During deployment, the tag object is merged into resource definitions.
*   `SecurityControl=Ignore` signals governance to allow these workloads under curated exemptions for training/demo environments.

***

## Testing Done

*   Verified tag appears on created resources.
*   Deployed into an MTT managed subscription to confirm policy no longer blocks templates.
*   Confirmed cleanup scripts still function as expected.

***

## Security & Compliance Notes

*   Tag adds **no privileges** and does not disable platform logging.
*   Still follow **data handling** and **cost controls** guidance.
*   **Do not** copy `SecurityControl=Ignore` into production or customer subscriptions.




## How to Validate

1.  Deploy to an MTT managed subscription.
2.  In Azure Portal, open the resource group → **Tags**: confirm
    *   `SecurityControl = Ignore`
3.  Confirm no policy denials block deployment.

***

## Checklist

*   [x] Tag applied at root of deployment so it flows to all resources
*   [x] Tested in MTT managed subscription
*   [x] No changes to SKUs/regions/quotas

***
