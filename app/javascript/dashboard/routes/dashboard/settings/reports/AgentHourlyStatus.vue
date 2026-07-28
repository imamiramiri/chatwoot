<script>
import V4Button from 'dashboard/components-next/button/Button.vue';
import { useAlert } from 'dashboard/composables';
import ReportFilters from './components/ReportFilters.vue';
import ReportHeader from './components/ReportHeader.vue';
import ReportsAPI from 'dashboard/api/reports';
import {
  downloadCsvFile,
  generateFileName,
} from 'dashboard/helper/downloadHelper';

export default {
  name: 'AgentHourlyStatusReport',
  components: {
    ReportHeader,
    ReportFilters,
    V4Button,
  },
  data() {
    return {
      from: 0,
      to: 0,
      rows: [],
      isLoading: false,
    };
  },
  computed: {
    agents() {
      return [...new Set(this.rows.map(row => row.agent_name))].sort();
    },
    rowsByAgent() {
      const grouped = {};
      this.rows.forEach(row => {
        if (!grouped[row.agent_name]) {
          grouped[row.agent_name] = [];
        }
        grouped[row.agent_name].push(row);
      });
      Object.keys(grouped).forEach(key => {
        grouped[key].sort((a, b) => Number(a.hour) - Number(b.hour));
      });
      return grouped;
    },
  },
  methods: {
    formatHour(hour) {
      return `${String(hour).padStart(2, '0')}:00`;
    },
    async fetchData() {
      if (!this.from || !this.to) return;
      this.isLoading = true;
      try {
        const { data } = await ReportsAPI.getAgentHourlyStatus({
          from: this.from,
          to: this.to,
        });
        this.rows = data || [];
      } catch {
        useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
      } finally {
        this.isLoading = false;
      }
    },
    async downloadReport() {
      try {
        const { data } = await ReportsAPI.getAgentHourlyStatusCSV({
          from: this.from,
          to: this.to,
        });
        downloadCsvFile(
          generateFileName({ type: 'agent-hourly-status', to: this.to }),
          data
        );
      } catch {
        useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
      }
    },
    onFilterChange({ from, to }) {
      this.from = from;
      this.to = to;
      this.fetchData();
    },
  },
};
</script>

<template>
  <ReportHeader :header-title="$t('REPORT.AGENT_HOURLY_STATUS.HEADER')">
    <V4Button
      :label="$t('REPORT.AGENT_HOURLY_STATUS.DOWNLOAD')"
      icon="i-ph-download-simple"
      size="sm"
      @click="downloadReport"
    />
  </ReportHeader>
  <div class="flex flex-col">
    <ReportFilters
      :show-entity-filter="false"
      :show-group-by="false"
      :show-business-hours="false"
      @filter-change="onFilterChange"
    />

    <div v-if="isLoading" class="py-6 text-sm text-n-slate-11">
      {{ $t('REPORT.LOADING_CHART') }}
    </div>

    <div v-else-if="!rows.length" class="py-6 text-sm text-n-slate-11">
      {{ $t('REPORT.NO_ENOUGH_DATA') }}
    </div>

    <div v-else class="flex flex-col gap-8 mt-4">
      <div v-for="agent in agents" :key="agent" class="flex flex-col gap-2">
        <h3 class="text-base font-medium text-n-slate-12">
          {{ agent }}
        </h3>
        <table class="w-full text-sm border-collapse">
          <thead>
            <tr class="text-left text-n-slate-11">
              <th class="py-2 pr-4 font-normal">
                {{ $t('REPORT.AGENT_HOURLY_STATUS.HOUR') }}
              </th>
              <th class="py-2 pr-4 font-normal">
                {{ $t('REPORT.AGENT_HOURLY_STATUS.ASSIGNED') }}
              </th>
              <th class="py-2 pr-4 font-normal">
                {{ $t('REPORT.AGENT_HOURLY_STATUS.OPEN') }}
              </th>
              <th class="py-2 pr-4 font-normal">
                {{ $t('REPORT.AGENT_HOURLY_STATUS.PENDING') }}
              </th>
              <th class="py-2 pr-4 font-normal">
                {{ $t('REPORT.AGENT_HOURLY_STATUS.SNOOZED') }}
              </th>
              <th class="py-2 pr-4 font-normal">
                {{ $t('REPORT.AGENT_HOURLY_STATUS.RESOLVED') }}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="row in rowsByAgent[agent]"
              :key="row.hour"
              class="border-t border-n-weak text-n-slate-12"
            >
              <td class="py-2 pr-4">{{ formatHour(row.hour) }}</td>
              <td class="py-2 pr-4 font-medium">{{ row.total_count }}</td>
              <td class="py-2 pr-4">{{ row.open_count }}</td>
              <td class="py-2 pr-4">{{ row.pending_count }}</td>
              <td class="py-2 pr-4">{{ row.snoozed_count }}</td>
              <td class="py-2 pr-4">{{ row.resolved_count }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
