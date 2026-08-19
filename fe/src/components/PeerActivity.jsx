const labels = {
  fork: 'Fork',
  serve: 'Repository read',
  push: 'Update',
  'pull-request': 'Pull request',
}

const notificationLabels = {
  issue: 'Issue',
  'issue-comment': 'Issue comment',
  'pull-request': 'Pull request',
  'pull-comment': 'Pull request comment',
}

export default function PeerActivity({ activity, notifications = [], onClear, onCancel }) {
  const hasItems = activity.length > 0 || notifications.length > 0
  return (
    <section className="activity-popover" aria-label="Urgit activity">
      <header>
        <div><strong>Activity</strong></div>
        {hasItems && <button className="text-button" onClick={onClear}>Clear</button>}
      </header>
      {!hasItems ? <div className="activity-empty">No activity.</div> : (
        <div className="activity-scroll">
          {!!notifications.length && <div className="activity-section-label">Notifications</div>}
          {!!notifications.length && <div className="activity-list">
            {notifications.map((event) => (
              <div className="activity-row" key={`notification-${event.id}`} title={event.when}>
                <span className="activity-dot notification" />
                <div>
                  <strong>{notificationLabels[event.event] || event.event} · {event.repository}</strong>
                  <small>{event.message}</small>
                </div>
                <span className="activity-state">new</span>
              </div>
            ))}
          </div>}
          {!!activity.length && <div className="activity-section-label">Peer</div>}
          {!!activity.length && <div className="activity-list">
          {activity.map((event) => (
            <div className="activity-row" key={event.id} title={event.when}>
              <span className={`activity-dot ${event.status}`} />
              <div>
                <strong>{labels[event.kind] || event.kind} · {event.repository}</strong>
                <small>{event.direction} {event.ship} · {event.message}</small>
              </div>
              {event.status === 'active' && event.kind === 'fork' ? (
                <button className="activity-cancel" onClick={() => onCancel(event.id)}>Cancel</button>
              ) : <span className={`activity-state ${event.status}`}>{event.status}</span>}
            </div>
          ))}
          </div>}
        </div>
      )}
    </section>
  )
}
