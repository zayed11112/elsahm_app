            {/* Stats Cards */}
            <Grid container spacing={3} sx={{ mb: 4 }}>
              <Grid item xs={12} sm={6} md={3}>
                <StatCard
                  title="العقارات"
                  value={stats?.propertiesCount ?? 0}
                  icon={<HomeIcon />}
                  color="#1976d2"
                />
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <StatCard
                  title="المستخدمين"
                  value={stats?.usersCount ?? 0}
                  icon={<PeopleIcon />}
                  color="#2e7d32"
                />
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <StatCard
                  title="الحجوزات"
                  value={stats?.reservationsCount ?? 0}
                  icon={<BookOnlineIcon />}
                  color="#ed6c02"
                />
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <StatCard
                  title="الإيرادات"
                  value={formatPrice(stats?.revenue ?? 0)}
                  icon={<MonetizationOnIcon />}
                  color="#9c27b0"
                />
              </Grid>
            </Grid> 