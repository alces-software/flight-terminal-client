/*=============================================================================
 * Copyright (C) 2018 Stephen F. Norledge and Alces Flight Ltd.
 *
 * This file is part of Flight Launch.
 *
 * All rights reserved, see LICENSE.txt.
 *===========================================================================*/
import React from 'react';
import PropTypes from 'prop-types';
import styled from 'styled-components';
import { Container, Row, Col } from 'reactstrap';
import { PageHeading, Section, makeSection } from 'flight-reactware';
import { compose } from 'recompose';

import clusters from '../../clusters';

import ComputeUnitUsageReport from '../components/ComputeUnitUsageReport';
import UserComputeUnitUsageReport from '../components/UserComputeUnitUsageReport';

const sections = {
  overview: makeSection('Compute credit usage overview', 'overview', 'blue', 'ticket'), 
  report: makeSection('Compute credit usage report', 'report', 'green', 'book'),
};

const EqualHeightRow = styled(Row)`
  display: flex;
  flex-wrap: wrap;
  & > [class*='col-'] {
    display: flex;
    flex-direction: column;
    margin-bottom: 6px;
  }

  ${ComputeUnitUsageReport} {
      flex: 1;
  }
`;

const Report = ({ clusters }) => {
  return (
    <Container >
      <PageHeading
        overview="View your current compute credits and your compute credit
        usage."
        sections={Object.values(sections)}
        title="Your compute credit usage."
      />
      <Section
        overview="Below you will find a list of all your clusters which have
        consumed your compute credits."
        section={sections.overview}
        title="Your current compute credits."
      >
        <Row>
          <Col
            lg={4}
            md={6}
            sm={12}
            xl={4}
            xs={12}
          >
            <UserComputeUnitUsageReport clusters={clusters} />
          </Col>
        </Row>
      </Section>
      <Section
        overview="Below you will find a list of all your clusters which have
        consumed your compute credits."
        section={sections.report}
        title="Your compute credit usage report."
      >
        <EqualHeightRow>
          {
            clusters.map(cluster => (
              <Col
                key={cluster.id}
                lg={4}
                md={6}
                sm={12}
                xl={4}
                xs={12}
              >
                <ComputeUnitUsageReport
                  cluster={cluster}
                  outlineStatus
                />
              </Col>
            ))
          }
        </EqualHeightRow>
      </Section>
    </Container>
  );
};

Report.propTypes = {
  clusters: PropTypes.arrayOf(PropTypes.object).isRequired,
};

const enhance = compose(
  clusters.withClusters,
);

export default enhance(Report);