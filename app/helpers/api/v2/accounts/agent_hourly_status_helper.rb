module Api::V2::Accounts::AgentHourlyStatusHelper
  # Conversations grouped by assigned agent and hour-of-day,
  # split by their current status (open / resolved / pending / snoozed).
  #
  # Hour is derived from conversations.created_at converted to the
  # requested timezone, so buckets match local working hours.
  def generate_agent_hourly_status_report
    connection = ActiveRecord::Base.connection

    tz_name = resolve_timezone_name
    account_id = Current.account.id.to_i
    since_time = format_timestamp(params[:since])
    until_time = format_timestamp(params[:until])

    sql = <<~SQL.squish
      SELECT
        COALESCE(u.name, 'Unassigned') AS agent_name,
        c.assignee_id AS agent_id,
        EXTRACT(
          HOUR FROM (c.created_at AT TIME ZONE 'UTC' AT TIME ZONE #{connection.quote(tz_name)})
        )::int AS hour,
        COUNT(*) FILTER (WHERE c.status = 0) AS open_count,
        COUNT(*) FILTER (WHERE c.status = 1) AS resolved_count,
        COUNT(*) FILTER (WHERE c.status = 2) AS pending_count,
        COUNT(*) FILTER (WHERE c.status = 3) AS snoozed_count,
        COUNT(*) AS total_count
      FROM conversations c
      LEFT JOIN users u ON u.id = c.assignee_id
      WHERE c.account_id = #{account_id}
        AND c.created_at >= #{connection.quote(since_time)}
        AND c.created_at < #{connection.quote(until_time)}
      GROUP BY 1, 2, 3
      ORDER BY 1, 3
    SQL

    connection.select_all(sql).to_a.map do |row|
      {
        'agent_name' => row['agent_name'],
        'agent_id' => row['agent_id'],
        'hour' => row['hour'].to_i,
        'open_count' => row['open_count'].to_i,
        'resolved_count' => row['resolved_count'].to_i,
        'pending_count' => row['pending_count'].to_i,
        'snoozed_count' => row['snoozed_count'].to_i,
        'total_count' => row['total_count'].to_i
      }
    end
  end

  private

  # PostgreSQL needs the IANA identifier (e.g. "Asia/Tehran").
  # ActiveSupport::TimeZone#name returns the Rails friendly name
  # (e.g. "Tehran"), which PostgreSQL does not recognise, so we
  # read the identifier from tzinfo instead.
  def resolve_timezone_name
    offset = (params[:timezone_offset] || 0).to_f
    zone = ActiveSupport::TimeZone[offset]
    zone&.tzinfo&.name || zone&.name || 'UTC'
  rescue StandardError
    'UTC'
  end

  def format_timestamp(value)
    Time.at(value.to_i).utc.strftime('%Y-%m-%d %H:%M:%S')
  end
end
