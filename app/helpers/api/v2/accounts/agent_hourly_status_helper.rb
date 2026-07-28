module Api::V2::Accounts::AgentHourlyStatusHelper
  # Conversations grouped by assigned agent and hour-of-day,
  # split by their current status (open / resolved / pending / snoozed).
  #
  # Hour is derived from conversations.created_at converted to the
  # requested timezone, so buckets match what the agent actually saw.
  def generate_agent_hourly_status_report
    tz = ActiveSupport::TimeZone[(params[:timezone_offset] || 0).to_f]&.name || 'UTC'

    sql = <<~SQL.squish
      SELECT
        COALESCE(u.name, :unassigned) AS agent_name,
        c.assignee_id AS agent_id,
        EXTRACT(HOUR FROM (c.created_at AT TIME ZONE 'UTC' AT TIME ZONE :tz))::int AS hour,
        COUNT(*) FILTER (WHERE c.status = 0) AS open_count,
        COUNT(*) FILTER (WHERE c.status = 1) AS resolved_count,
        COUNT(*) FILTER (WHERE c.status = 2) AS pending_count,
        COUNT(*) FILTER (WHERE c.status = 3) AS snoozed_count,
        COUNT(*) AS total_count
      FROM conversations c
      LEFT JOIN users u ON u.id = c.assignee_id
      WHERE c.account_id = :account_id
        AND c.created_at >= :since_time
        AND c.created_at < :until_time
      GROUP BY 1, 2, 3
      ORDER BY 1, 3
    SQL

    query = ActiveRecord::Base.sanitize_sql_array(
      [
        sql,
        {
          account_id: Current.account.id,
          since_time: Time.at(params[:since].to_i).utc,
          until_time: Time.at(params[:until].to_i).utc,
          tz: tz,
          unassigned: 'Unassigned'
        }
      ]
    )

    ActiveRecord::Base.connection.select_all(query).to_a
  end
end
