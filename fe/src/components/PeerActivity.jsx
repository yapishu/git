const labels = {
  fork: 'Fork',
  serve: 'Repository read',
  push: 'Update',
  'pull-request': 'Pull request',
}

export default function PeerActivity({ activity, onClear }) {
  return (
    <section className="activity-popover" aria-label="Peer activity">
      <header>
        <div><strong>Peer activity</strong><small>Ames and Fine operations</small></div>
        {!!activity.length && <button className="text-button" onClick={onClear}>Clear</button>}
      </header>
      {!activity.length ? <div className="activity-empty">No peer activity.</div> : (
        <div className="activity-list">
          {activity.map((event) => (
            <div className="activity-row" key={event.id} title={event.when}>
              <span className={`activity-dot ${event.status}`} />
              <div>
                <strong>{labels[event.kind] || event.kind} · {event.repository}</strong>
                <small>{event.direction} {event.ship} · {event.message}</small>
              </div>
              <span className={`activity-state ${event.status}`}>{event.status}</span>
            </div>
          ))}
        </div>
      )}
    </section>
  )
}
