# PostHog Helm Charts

This directory contains Helm charts for deploying PostHog with recommended defaults.

## Topology Spread Constraints

The charts include default topology spread constraints that ensure high availability by distributing pods across availability zones and nodes.

### Default Configuration

```yaml
topologySpreadConstraints:
  # Primary: evenly distribute across AZs
  - maxSkew: 2
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    nodeTaintsPolicy: Honor
    labelSelector:
      matchLabels: {}
    minDomains: 3
    matchLabelKeys:
      - pod-template-hash
      - app
      - release
      - role
      - app.kubernetes.io/name
      - app.kubernetes.io/instance
  # Secondary: spread across nodes within zones
  - maxSkew: 2
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
    nodeTaintsPolicy: Honor
    labelSelector:
      matchLabels: {}
    minDomains: 5
    matchLabelKeys:
      - pod-template-hash
      - app
      - release
      - role
      - app.kubernetes.io/name
      - app.kubernetes.io/instance
```

### Constraint Details

#### Primary Constraint (Zone Distribution)
- **Purpose**: Evenly distribute pods across availability zones for zone-level failure tolerance
- **maxSkew: 2**: Allows at most 2 pods difference between zones
- **minDomains: 3**: Requires at least 3 zones to schedule
- **whenUnsatisfiable: DoNotSchedule**: Strictly enforces the constraint

#### Secondary Constraint (Node Distribution)
- **Purpose**: Spread pods across nodes within zones to avoid single-node failures
- **maxSkew: 2**: Allows at most 2 pods difference between nodes
- **minDomains: 5**: Requires at least 5 nodes to schedule
- **whenUnsatisfiable: DoNotSchedule**: Strictly enforces the constraint

### Key Features

- **nodeTaintsPolicy: Honor**: Respects node taints when calculating spread
- **matchLabelKeys**: Uses multiple label keys for intelligent pod grouping:
  - `pod-template-hash`: Groups by deployment revision
  - `app`, `release`, `role`: Application-level grouping
  - `app.kubernetes.io/name`, `app.kubernetes.io/instance`: Standard Kubernetes labels

### Customization

To override the default constraints, specify your own in your values file:

```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: ScheduleAnyway
    # ... your custom configuration
```

To disable topology constraints entirely:

```yaml
topologySpreadConstraints: []
```
