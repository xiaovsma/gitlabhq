<script>
import { mapState } from 'vuex';
import { GlButton, GlForm, GlTooltipDirective } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { __ } from '~/locale';

export default {
  name: 'ApproveAccessRequestButton',
  csrf,
  title: __('Grant access'),
  components: { GlButton, GlForm },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    memberId: {
      type: Number,
      required: true,
    },
  },
  computed: {
    ...mapState(['memberPath']),
    approvePath() {
      return this.memberPath.replace(/:id$/, `${this.memberId}/approve_access_request`);
    },
  },
};
</script>

<template>
  <gl-form :action="approvePath" method="post">
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <gl-button
      v-gl-tooltip.hover
      :title="$options.title"
      :aria-label="$options.title"
      icon="check"
      variant="success"
      type="submit"
    />
  </gl-form>
</template>
