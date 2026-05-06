import http from 'k6/http';
import { check } from 'k6';

export const options = {
  // Crank up the virtual users to 200
  vus: 200, 
  // Run for 4 minutes to ensure AWS CloudWatch catches the spike
  duration: '4m', 
};

export default function () {
  // Replace with your URL
  const res = http.get('https://jpk6h6z7ge.eu-west-3.awsapprunner.com/health');
  
  check(res, { 'status was 200': (r) => r.status == 200 });
  
  // These 200 users will now hammer the server absolutely as fast as their network allows.
}