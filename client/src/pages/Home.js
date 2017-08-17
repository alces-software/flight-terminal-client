import React from 'react';
import {
  Container,
  Row,
  Col,
} from 'reactstrap';

import branding from '../modules/branding';
import ContextLink from '../elements/ContextLink';
import CommunitySiteLink from '../elements/CommunitySiteLink';
import DocsSiteLink from '../elements/DocsSiteLink';

const Home = () => {
  return (
    <div>
      <div className="d-flex justify-content-center">
        <div>
          <div className="d-flex justify-content-center">
            <h1>
              Welcome to the Alces Flight Launch Service!
            </h1>
          </div>
          <div className="d-flex justify-content-center">
            <branding.WithBranding>
              {(branding) => <h3>{branding.navEntry}</h3>}
            </branding.WithBranding>
          </div>
        </div>
        <branding.Logo height="100px" />
      </div>
      <Container fluid>
        <Row>
          <Col>
            <p>
              On behalf of the Alces Flight Crew we’d like to welcome you on
              board the Alces Flight Launch service. This service has been
              developed to quickly launch a preconfigured High Performance
              Computing (HPC) cluster. With the Alces Flight Launch service
              you gain temporary access to instant, single-user scientific
              computing at no cost to you.
            </p>

            <h5>What is the Alces Flight Launch service?</h5>
            <p>
              The Alces Flight Launch service rapidly delivers a whole HPC
              cluster, ready to go, complete with job scheduler and
              applications.  Simply select the HPC cluster you want to
              evaluate, enter your Flight Launch token, cluster name, and an
              email address for notifications and you are ready to go!
            </p>
            <p>
              Clusters are deployed in a Virtual Private Cluster (VPC)
              environment for security, with SSH and graphical-desktop
              connectivity for users.  Data management tools for POSIX and S3
              object storage are also included to help users transfer files
              and manage storage resources.
            </p>

            <h5>How to use a Flight Launch token</h5>
            <p>
              Through one of the Alces Flight Crew or via our trusted partner
              network you should have a received a Flight Launch token
              consisting of three unrelated words (e.g. “flower – star –
              moose”). Don’t have one yet?{' '}
              <a
                href="mailto:flight@alces-flight.com?subject=Flight Launch
                Token Request&body=Please send me a Flight Launch Token by
                return email.%0D%0A%0D%0AKind regards."
                rel="noopener noreferrer"
                target="_blank"
              >
                Let us know
              </a> and we’ll start the process of securing you a Flight
              Launch token.
            </p>
            <p>
              Once you’ve secured a token simply search through the available
              preconfigured clusters. When you’ve decided the HPC cluster you
              wish to trial enter the token, the name you’d like to give your
              cluster, and the email address you want to receive status
              updates to.
            </p>
            <p>
              Then, simply press launch! You are now moments away from HPC
              cluster access.
            </p>
          </Col>
          <Col>
            <h5>Using your preconfigured HPC cluster</h5>
            <p>
              Once you are notified that your HPC cluster is active you can
              use the pre-determined time as you see fit. Work with the
              applications that come pre-installed or try your hand at
              installing and running applications from the{' '}
              <ContextLink
                linkSite="Gridware"
                location="/"
              >
                Alces Gridware open source application library
              </ContextLink>.
            </p>
            <p>
              While we’ll send you emails to let you know when your HPC
              cluster has been launched, remember this is a trial service and
              is time limited. Please remember to save any work you perform
              while using your Flight Launch cluster!
            </p>

            <h5>Getting ready to launch and more information</h5>
            <p>
              Want to spend some time reading up on the Alces Flight Launch
              service prior to starting your evaluation? We have a{' '}
              <DocsSiteLink>documentation site</DocsSiteLink> dedicated to the
              cause as well as a {' '}
              <CommunitySiteLink>Community Support Portal</CommunitySiteLink>
              {' '} available for you to join in and read through.
            </p>
            <p>
              Enjoy your flight!
            </p>
          </Col>
        </Row>
      </Container>
    </div>
  );
};

export default Home;
