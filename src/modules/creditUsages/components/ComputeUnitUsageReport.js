import React from 'react';
import PropTypes from 'prop-types';
import FontAwesome from 'react-fontawesome';
import TimeAgo from 'react-timeago';
import { Card, CardHeader } from 'reactstrap';
import { compose, setStatic } from 'recompose';
import { connect } from 'react-redux';
import { createStructuredSelector } from 'reselect';
import { Styles } from 'flight-reactware';
import { Link } from 'react-router-dom';

import payments from '../../payments';

import withCreditUsageContext from './withCreditUsageContext';
import ConsumptionLimit from './ConsumptionLimit';
import CurrentCreditConsumption from './CurrentCreditConsumption';
import StatusText from './StatusText';
import TotalCreditConsumption from './TotalCreditConsumption';
import { CardMedias, CardMedia } from './CardMedia';

const ComputeUnitUsageReport = ({
  className,
  cluster,
  outlineStatus,
  payment,
}) => {
  const {
    clusterName,
    status,
    gracePeriodExpiresAt,
    hostname,
  } = cluster.attributes;
  const isTerminated = status === 'TERMINATION_COMPLETE';
  return (
    <Card
      className={className}
      color={!outlineStatus ? undefined : isTerminated ? 'danger' : 'success'}
      outline={outlineStatus}
    >
      <CardHeader>
        <span>Compute unit usage</span>
        <span className="pull-right">
          <FontAwesome name="line-chart" />
        </span>
      </CardHeader>
      <CardMedias>
        <CardMedia
          iconName="server"
          title="Cluster name:"
        >
          {
            hostname ?
              <Link to={`/access/${hostname}`} >
                { clusterName }
              </Link> :
              clusterName
          }
        </CardMedia>
        <CardMedia
          iconName={isTerminated ? 'times-circle' : 'check-circle'}
          title="Status:"
        >
          <StatusText
            gracePeriodExpiresAt={gracePeriodExpiresAt}
            status={status}
          />
        </CardMedia>
        <CardMedia
          iconName="clock-o"
          title="Grace period expiration:"
        >
          {
            !isTerminated && gracePeriodExpiresAt
              ? <span><TimeAgo date={gracePeriodExpiresAt} />.</span>
              : <span>N/A</span>
          }
        </CardMedia>
        <CardMedia
          iconName="line-chart"
          title="Compute unit burn rate:"
        >
          <CurrentCreditConsumption
            cluster={cluster}
          />
        </CardMedia>
        <CardMedia
          iconName="ticket"
          title="Total consumption:"
        >
          <TotalCreditConsumption
            cluster={cluster}
            payment={payment}
          />
        </CardMedia>
        <CardMedia
          iconName="bullseye"
          title="Consumption limit:"
        >
          <ConsumptionLimit payment={payment} />
        </CardMedia>
      </CardMedias>
    </Card>
  );
};

ComputeUnitUsageReport.propTypes = {
  className: PropTypes.string,
  cluster: PropTypes.object.isRequired,
  outlineStatus: PropTypes.bool.isRequired,
  payment: PropTypes.object,
};

ComputeUnitUsageReport.defaultProps = {
  outlineStatus: false,
};

const enhance = compose(
  setStatic('manageItemKey', 'computeUnitUsageReport'),

  Styles.withStyles``,

  connect(createStructuredSelector({
    payment: payments.selectors.paymentForCluster,
  })),

  withCreditUsageContext,
);

export default enhance(ComputeUnitUsageReport);