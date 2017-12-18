plot(Erik150801Vb,RPCLAP20150801000000914I1S(j,:));
ax = gca;
ax.YLim=[-1E-7 1E-8];
legend(Erik150801UTC(j))
dx= 2;

text(shit+dx,RPCLAP20150801000000914I1S(j,55)+dy,sprintf('Ion slope = %s',ion_slope(j+1)));
grid on;
 ax.YLabel.String='I [A]';
ax.XLabel.String='Vb [V]';